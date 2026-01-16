from jinja2 import Template

import json
import logging
import os
import subprocess
import re

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

def run(cmd):
    """Run a shell command and fail fast on error."""
    subprocess.run(cmd, check=True)

def chmod(path, mode):
    os.chmod(path, mode)

def generate_certificate(common_name):
    """
    Generate a self signed SSL certificate with the given common name. When called
    multiple times it will reuse the same auto generated certificate authority.

    :param common_name: Common name for the certificate, it will be also used to
    name the certificate ans key files.
    """
    if not (common_name or common_name.strip()):
        raise ValueError("common_name cannot be empty or contain white spaces")

    user_cert_cn = common_name
    user_cert_file_name = user_cert_cn

    # Directories
    ca_dir = "customCA"
    certs_dir = os.path.join(ca_dir, "certs")
    private_dir = os.path.join(ca_dir, "private")

    os.makedirs(certs_dir, exist_ok=True)
    os.makedirs(private_dir, exist_ok=True)

    chmod(private_dir, 0o700)

    ca_key = os.path.join(private_dir, "ca.key")
    ca_cert = os.path.join(certs_dir, "ca.crt")

    # Generate CA if needed
    if not os.path.isfile(ca_cert):
        if not os.path.isfile(ca_key):
            run([
                "openssl", "genrsa",
                "-out", ca_key,
                "4096"
            ])
            chmod(ca_key, 0o600)

        run([
            "openssl", "req",
            "-x509", "-new", "-nodes",
            "-key", ca_key,
            "-sha256",
            "-days", "1024",
            "-out", ca_cert,
            "-subj", "/C=FR/L=Paris/O=ANEO/CN=ANEO Armonik Test - Private Certificate Authority"
        ])

        chmod(ca_cert, 0o644)
        logger.info("CA certificate generated successfully")
    else:
        logger.info("CA certificate already exists")

    # User key
    user_key = os.path.join(private_dir, f"{user_cert_file_name}.key")
    run([
        "openssl", "genrsa",
        "-out", user_key,
        "4096"
    ])
    chmod(user_key, 0o644)

    # CSR
    csr = os.path.join(ca_dir, f"{user_cert_file_name}.csr")
    run([
        "openssl", "req",
        "-new",
        "-key", user_key,
        "-out", csr,
        "-subj", f"/C=FR/L=Paris/O=ANEO/CN={user_cert_cn}",
        "-addext", f"subjectAltName = DNS:{user_cert_cn},DNS:localhost,IP:127.0.0.1"
    ])


    #extensions file
    current_path = os.path.dirname(os.path.abspath(__file__))
    extensions_file = os.path.join(current_path, "openssl.extensions.conf")

    # User certificate
    user_cert = os.path.join(certs_dir, f"{user_cert_file_name}.crt")
    run([
        "openssl", "x509",
        "-req",
        "-in", csr,
        "-CA", ca_cert,
        "-CAkey", ca_key,
        "-CAcreateserial",
        "-out", user_cert,
        "-days", "3",
        "-sha256",
        "-extfile", extensions_file,
        "-extensions", "v3_req"
    ])

    chmod(user_cert, 0o644)

    # PKCS12
    p12 = os.path.join(certs_dir, f"{user_cert_file_name}.p12")
    run([
        "openssl", "pkcs12",
        "-export",
        "-out", p12,
        "-inkey", user_key,
        "-in", user_cert,
        "-certfile", ca_cert,
        "-passout", "pass:"
    ])

    # SHA1 fingerprint
    result = subprocess.check_output([
        "openssl", "x509",
        "-in", user_cert,
        "-noout",
        "-fingerprint"
    ], text=True)

    fingerprint = re.sub(r".*=", "", result).replace(":", "").strip().lower()
    user_name = re.sub(r'[^a-zA-Z\s]', '', user_cert_cn)
    return {"Cn": user_cert_cn,"Fingerprint": fingerprint, "Username": user_name}

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
    template_str = '''{
    "certificates_list": {{ certificates_list | tojson(indent=2) }},
    "users_list": {{ users_list | tojson(indent=2) }},
    "roles_list": {{ roles_list | tojson(indent=2) }}
    }
    '''

    template = Template(template_str)

    rendered_config = template.render(
        certificates_list=certificates_list,
        users_list=users_list,
        roles_list=roles_list
    )

    formatted_config  = json.dumps(json.loads(rendered_config), indent=2)
    auth_json_file = "auth_conf.json"
    with open(auth_json_file, "w", encoding='utf-8') as f:
        f.write(formatted_config)

    return os.path.abspath(auth_json_file)
                           
def generate_auth_params_tfvars(ca_file_path, auth_json_path):
    """
    Generates terraform configuration object to be passed as extra_params.tfvars
    to the deployment.
    """
    template_str = """
    ingress = {
      tls                  = true
      mtls                 = true
      generate_client_cert = false
      custom_client_ca_file = "{{ custom_client_ca_file }}"
    }

    authentication = {
       require_authentication = true
       require_authorization = true
       authentication_datafile = "{{ authentication_datafile }}"
       trusted_common_names = {{ trusted_common_names | tojson }}
    }
    """

    context = {
        'custom_client_ca_file': ca_file_path,
        'authentication_datafile': auth_json_path,
        'trusted_common_names': TRUSTED_CNS
    }

    template = Template(template_str)
    output = template.render(context)
    tfvars_file = './auth_params.tfvars'

    with open(tfvars_file, 'w') as output_file:
        output_file.write(output)

ROLES_LIST =[
    {
      "RoleName":"Admin",
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
        "HealthChecks:CheckHealth"
      ]
    },
    {
      "RoleName":"Monitoring",
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
        "HealthChecks:CheckHealth"
      ]
    }
]

if __name__ == '__main__':
    certs_list = create_certs()
    users_list = [{"Username":r['Username'], "Roles":["Monitoring" if "monitoring" in r['Username'] else "Admin"]} for r in certs_list]
    auth_json_path = generate_auth_json_file(certs_list,users_list,ROLES_LIST)
    ca_cert_path = os.path.abspath(os.path.join("customCA", "ca.crt"))
    generate_auth_params_tfvars(ca_cert_path,auth_json_path)