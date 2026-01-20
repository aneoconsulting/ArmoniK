from jinja2 import Template

import json
import logging
import os
import re

from datetime import datetime, UTC, timedelta
from cryptography import x509
from cryptography.x509.oid import NameOID, ExtendedKeyUsageOID
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import rsa
from cryptography.hazmat.primitives.serialization.pkcs12 import (
    serialize_key_and_certificates,
)
from datetime import datetime, timedelta
import ipaddress

logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)


def write_file(path, data, mode):
    with open(path, "wb") as f:
        f.write(data)
    os.chmod(path, mode)


def generate_certificate(common_name: str):
    if not (common_name and common_name.strip()):
        raise ValueError("common_name cannot be empty or contain white spaces")

    ca_dir = "customCA"
    certs_dir = os.path.join(ca_dir, "certs")
    private_dir = os.path.join(ca_dir, "private")

    os.makedirs(certs_dir, exist_ok=True)
    os.makedirs(private_dir, exist_ok=True)
    os.chmod(private_dir, 0o700)

    ca_key_path = os.path.join(private_dir, "ca.key")
    ca_cert_path = os.path.join(certs_dir, "ca.crt")

    # -------------------------
    # Create / load CA
    # -------------------------
    if not os.path.exists(ca_cert_path):
        logger.info("Generating CA")

        ca_key = rsa.generate_private_key(
            public_exponent=65537,
            key_size=4096,
        )

        ca_subject = x509.Name(
            [
                x509.NameAttribute(NameOID.COUNTRY_NAME, "FR"),
                x509.NameAttribute(NameOID.LOCALITY_NAME, "Paris"),
                x509.NameAttribute(NameOID.ORGANIZATION_NAME, "ANEO"),
                x509.NameAttribute(
                    NameOID.COMMON_NAME,
                    "ANEO Armonik Test - Private Certificate Authority",
                ),
            ]
        )

        ca_cert = (
            x509.CertificateBuilder()
            .subject_name(ca_subject)
            .issuer_name(ca_subject)
            .public_key(ca_key.public_key())
            .serial_number(x509.random_serial_number())
            .not_valid_before(datetime.now(UTC))
            .not_valid_after(datetime.now(UTC) + timedelta(days=1))
            .add_extension(
                x509.BasicConstraints(ca=True, path_length=None),
                critical=True,
            )
            .add_extension(
                x509.KeyUsage(
                    digital_signature=True,
                    content_commitment=False,
                    key_encipherment=False,
                    data_encipherment=False,
                    key_agreement=False,
                    key_cert_sign=True,
                    crl_sign=True,
                    encipher_only=False,
                    decipher_only=False,
                ),
                critical=True,
            )
            .sign(ca_key, hashes.SHA256())
        )

        write_file(
            ca_key_path,
            ca_key.private_bytes(
                serialization.Encoding.PEM,
                serialization.PrivateFormat.TraditionalOpenSSL,
                serialization.NoEncryption(),
            ),
            0o644,
        )

        write_file(
            ca_cert_path,
            ca_cert.public_bytes(serialization.Encoding.PEM),
            0o644,
        )
    else:
        logger.info("CA certificate already exists")

        with open(ca_key_path, "rb") as f:
            ca_key = serialization.load_pem_private_key(f.read(), password=None)

        with open(ca_cert_path, "rb") as f:
            ca_cert = x509.load_pem_x509_certificate(f.read())

    # -------------------------
    # User key
    # -------------------------
    user_key = rsa.generate_private_key(
        public_exponent=65537,
        key_size=4096,
    )

    user_key_path = os.path.join(private_dir, f"{common_name}.key")
    write_file(
        user_key_path,
        user_key.private_bytes(
            serialization.Encoding.PEM,
            serialization.PrivateFormat.TraditionalOpenSSL,
            serialization.NoEncryption(),
        ),
        0o644,
    )

    # -------------------------
    # User certificate
    # -------------------------
    subject = x509.Name(
        [
            x509.NameAttribute(NameOID.COUNTRY_NAME, "FR"),
            x509.NameAttribute(NameOID.LOCALITY_NAME, "Paris"),
            x509.NameAttribute(NameOID.ORGANIZATION_NAME, "ANEO"),
            x509.NameAttribute(NameOID.COMMON_NAME, common_name),
        ]
    )

    # subjectAltName (OpenSSL equivalent)
    san = x509.SubjectAlternativeName(
        [
            x509.DNSName(common_name),
            x509.DNSName("localhost"),
            x509.IPAddress(ipaddress.IPv4Address("127.0.0.1")),
        ]
    )

    # keyUsage = digitalSignature, keyEncipherment
    key_usage = x509.KeyUsage(
        digital_signature=True,
        content_commitment=False,
        key_encipherment=True,
        data_encipherment=False,
        key_agreement=False,
        key_cert_sign=False,
        crl_sign=False,
        encipher_only=False,
        decipher_only=False,
    )

    # extendedKeyUsage = serverAuth, clientAuth
    extended_key_usage = x509.ExtendedKeyUsage(
        [
            ExtendedKeyUsageOID.SERVER_AUTH,
            ExtendedKeyUsageOID.CLIENT_AUTH,
        ]
    )

    user_cert = (
        x509.CertificateBuilder()
        .subject_name(subject)
        .issuer_name(ca_cert.subject)
        .public_key(user_key.public_key())
        .serial_number(x509.random_serial_number())
        .not_valid_before(datetime.now(UTC))
        .not_valid_after(datetime.now(UTC) + timedelta(days=1))
        .add_extension(san, critical=False)
        .add_extension(key_usage, critical=True)
        .add_extension(extended_key_usage, critical=False)
        .sign(ca_key, hashes.SHA256())
    )

    user_cert_path = os.path.join(certs_dir, f"{common_name}.crt")
    write_file(
        user_cert_path,
        user_cert.public_bytes(serialization.Encoding.PEM),
        0o644,
    )

    # -------------------------
    # PKCS12
    # -------------------------
    p12_data = serialize_key_and_certificates(
        name=common_name.encode(),
        key=user_key,
        cert=user_cert,
        cas=[ca_cert],
        encryption_algorithm=serialization.NoEncryption(),
    )

    p12_path = os.path.join(certs_dir, f"{common_name}.p12")
    write_file(p12_path, p12_data, 0o644)

    # -------------------------
    # Fingerprint
    # -------------------------
    fingerprint = user_cert.fingerprint(hashes.SHA1()).hex().lower()
    user_name = re.sub(r"[^a-zA-Z\s]", "", common_name)

    return {
        "Cn": common_name,
        "Fingerprint": fingerprint,
        "Username": user_name,
    }


TRUSTED_CNS = ["armonik.admin", "armonik.mcp"]
ALL_CNS = TRUSTED_CNS + ["armonik.monitoring"]


def create_certs():
    all_certs = []
    for cn in ALL_CNS:
        all_certs.append(generate_certificate(cn))
    return all_certs


def generate_auth_json_file(certificates_list, users_list, roles_list):
    """
    Generates authentication json file to be passed to the deployment
    """
    template_str = """{
    "certificates_list": {{ certificates_list | tojson(indent=2) }},
    "users_list": {{ users_list | tojson(indent=2) }},
    "roles_list": {{ roles_list | tojson(indent=2) }}
    }
    """

    template = Template(template_str)

    rendered_config = template.render(
        certificates_list=certificates_list,
        users_list=users_list,
        roles_list=roles_list,
    )

    formatted_config = json.dumps(json.loads(rendered_config), indent=2)
    auth_json_file = "auth_conf.json"
    with open(auth_json_file, "w", encoding="utf-8") as f:
        f.write(formatted_config)

    return os.path.abspath(auth_json_file)


ROLES_LIST = [
    {
        "RoleName": "Admin",
        "Permissions": [
            "Sessions:CreateSession",
            "Sessions:CancelSession",
            "Sessions:GetSession",
            "Sessions:ListSessions",
            "Sessions:PauseSession",
            "Sessions:CloseSession",
            "Sessions:PurgeSession",
            "Sessions:DeleteSession",
            "Sessions:ResumeSession",
            "Sessions:StopSubmission",
            "Tasks:GetTask",
            "Tasks:ListTasks",
            "Tasks:GetResultIds",
            "Tasks:CancelTasks",
            "Tasks:CountTasksByStatus",
            "Tasks:ListTasksDetailed",
            "Tasks:SubmitTasks",
            "Results:GetOwnerTaskId",
            "Results:ListResults",
            "Results:CreateResultsMetaData",
            "Results:CreateResults",
            "Results:DeleteResultsData",
            "Results:DownloadResultData",
            "Results:GetServiceConfiguration",
            "Results:UploadResultData",
            "Results:GetResult",
            "Results:ImportResultsData",
            "Applications:ListApplications",
            "Events:GetEvents",
            "General:Impersonate",
            "Partitions:GetPartition",
            "Partitions:ListPartitions",
            "Versions:ListVersions",
            "HealthChecks:CheckHealth",
        ],
    },
    {
        "RoleName": "Monitoring",
        "Permissions": [
            "Sessions:GetSession",
            "Sessions:ListSessions",
            "Sessions:PauseSession",
            "Sessions:ResumeSession",
            "Tasks:GetTask",
            "Tasks:ListTasks",
            "Tasks:GetResultIds",
            "Tasks:CountTasksByStatus",
            "Tasks:ListTasksDetailed",
            "Results:GetOwnerTaskId",
            "Results:ListResults",
            "Results:DownloadResultData",
            "Results:GetServiceConfiguration",
            "Results:UploadResultData",
            "Results:GetResult",
            "Results:ImportResultsData",
            "Applications:ListApplications",
            "Events:GetEvents",
            "Partitions:GetPartition",
            "Partitions:ListPartitions",
            "Versions:ListVersions",
            "HealthChecks:CheckHealth",
        ],
    },
]

if __name__ == "__main__":
    # Generate certs for the deployment, all will be signed by a common CA
    certs_list = create_certs()
    users_list = [
        {
            "Username": r["Username"],
            "Roles": ["Monitoring" if "monitoring" in r["Username"] else "Admin"],
        }
        for r in certs_list
    ]
    auth_json_path = generate_auth_json_file(certs_list, users_list, ROLES_LIST)

    # Generate another cert which wont be part of the deployment
    generate_certificate("armonik.norole")

    # Generate server certificates for the nginx in front of MCP
    generate_certificate("server.mcp")
