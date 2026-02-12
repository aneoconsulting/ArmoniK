import os
import subprocess
import re
import pytest
import shutil

from datetime import datetime, UTC, timedelta
from pathlib import Path
from typing import Callable, Iterator, Mapping, Any

from cryptography import x509
from cryptography.hazmat.backends import default_backend
from cryptography.hazmat.primitives import serialization, hashes
from cryptography.hazmat.primitives.asymmetric import rsa


UNAUTHENTICATED = "Unauthenticated"
INTERNAL = "Internal"


@pytest.fixture(scope="session")
def control_plane_endpoint() -> str:
    endpoint = os.environ.get("CONTROL_PLANE_URL")
    if endpoint is None:
        raise ValueError("CONTROL_PLANE_URL not defined")
    if endpoint.startswith("https://"):
        endpoint = endpoint[8:]
    return endpoint


@pytest.fixture(scope="session")
def certificate_authority() -> str:
    ca = os.environ.get("CACERT")
    if ca is None:
        raise ValueError("CACERT not defined")
    return ca


@pytest.fixture(scope="session")
def mcp_endpoint() -> str:
    endpoint = os.environ.get("MCP_URL")
    if endpoint is None:
        raise ValueError("MCP_URL not defined")
    if endpoint.startswith("https://"):
        endpoint = endpoint[8:]
    return endpoint


@pytest.fixture(scope="session")
def mcp_ca() -> str:
    ca = os.environ.get("MCP_CA")
    if ca is None:
        raise ValueError("MCP_CA not defined")
    return ca


@pytest.fixture(scope="session")
def custom_certs_root() -> str:
    custom_certs = os.environ.get("CUSTOM_CERTS_ROOT")
    if custom_certs is None:
        raise ValueError("CUSTOM_CERTS_ROOT not defined")
    return custom_certs


@pytest.fixture(scope="session")
def armonik_protos() -> Iterator[str]:
    repo_url: str = "https://github.com/aneoconsulting/ArmoniK.Api"
    clone_dir: str = "armonik_api_repo"

    subprocess.run(["git", "clone", repo_url, clone_dir], check=True)

    yield os.path.join(clone_dir, "Protos/V1")

    if os.path.exists(clone_dir):
        shutil.rmtree(clone_dir)


@pytest.fixture(scope="session")
def grpc_config(
    control_plane_endpoint: str,
    mcp_endpoint: str,
    armonik_protos: str,
    certificate_authority: str,
    mcp_ca: str,
) -> dict[str, str]:
    """
    Grpcurl configuration to be used in a test session, we use the CheckHealth RPC
    across all the tests. Since (as the writting of these tests), grpc reflection
    is not activated in the API, we need to provide the protobuf definitions to grpcurl.
    """
    return {
        "control_plane": control_plane_endpoint,
        "mcp": mcp_endpoint,
        "cacert": certificate_authority,
        "mcp_cacert": mcp_ca,
        "proto_path": armonik_protos,
        "proto_file": "health_checks_service.proto",
        "rpc": "armonik.api.grpc.v1.health_checks.HealthChecksService/CheckHealth",
        "request_data": "{}",
    }


@pytest.fixture(scope="session")
def unknown_cert(
    tmp_path_factory: pytest.TempPathFactory,
) -> Iterator[tuple[Path, Path]]:
    session_tmp_path: Path = tmp_path_factory.mktemp("certs")
    cert_file: Path = session_tmp_path / "mock_cert.crt"
    key_file: Path = session_tmp_path / "mock_key.key"

    private_key = rsa.generate_private_key(
        public_exponent=65537,
        key_size=2048,
        backend=default_backend(),
    )

    subject = x509.Name(
        [
            x509.NameAttribute(x509.NameOID.COUNTRY_NAME, "FR"),
            x509.NameAttribute(x509.NameOID.STATE_OR_PROVINCE_NAME, "Paris"),
            x509.NameAttribute(x509.NameOID.LOCALITY_NAME, "Paris"),
            x509.NameAttribute(x509.NameOID.ORGANIZATION_NAME, "ANEO"),
            x509.NameAttribute(x509.NameOID.COMMON_NAME, "unknown"),
        ]
    )

    certificate = (
        x509.CertificateBuilder()
        .subject_name(subject)
        .issuer_name(subject)
        .public_key(private_key.public_key())
        .serial_number(x509.random_serial_number())
        .not_valid_before(datetime.now(UTC))
        .not_valid_after(datetime.now(UTC) + timedelta(days=1))
        .add_extension(
            x509.SubjectAlternativeName([x509.DNSName("example.org")]),
            critical=False,
        )
        .sign(private_key, hashes.SHA256(), default_backend())
    )

    cert_file.write_text(certificate.public_bytes(serialization.Encoding.PEM).decode())
    key_file.write_text(
        private_key.private_bytes(
            encoding=serialization.Encoding.PEM,
            format=serialization.PrivateFormat.TraditionalOpenSSL,
            encryption_algorithm=serialization.NoEncryption(),
        ).decode()
    )

    yield cert_file, key_file


@pytest.fixture(scope="session")
def certs(
    custom_certs_root,
    unknown_cert: tuple[Path, Path],
) -> Mapping[str, tuple[str | Path, str | Path]]:
    return {
        "admin": (
            f"{custom_certs_root}/certs/armonik.admin.crt",
            f"{custom_certs_root}/private/armonik.admin.key",
        ),
        "monitoring": (
            f"{custom_certs_root}/certs/armonik.monitoring.crt",
            f"{custom_certs_root}/private/armonik.monitoring.key",
        ),
        "norole": (
            f"{custom_certs_root}/certs/armonik.norole.crt",
            f"{custom_certs_root}/private/armonik.norole.key",
        ),
        "unknown": unknown_cert,
    }


def extract_code(stderr: str) -> str | None:
    """Extract gRPC error code from grpcurl stderr."""
    match = re.search(r"Code:\s*(\w+)", stderr)
    return match.group(1) if match else None


def grpc_runner(
    grpc_config: Mapping[str, str],
) -> Callable[..., subprocess.CompletedProcess[str]]:
    """
    Wraps grpcurl into subprocess call with given grpc_config.
    """

    def run(
        *,
        cacert: str,
        cert: str | Path,
        key: str | Path,
        endpoint: str,
        headers: list[str] | None = None,
    ) -> subprocess.CompletedProcess[str]:
        command: list[str] = [
            "grpcurl",
            "-import-path",
            grpc_config["proto_path"],
            "-proto",
            grpc_config["proto_file"],
        ]

        if headers:
            for header in headers:
                command += ["-H", header]

        command += [
            "-cacert",
            str(cacert),
            "-cert",
            str(cert),
            "-key",
            str(key),
            "-d",
            grpc_config["request_data"],
            endpoint,
            grpc_config["rpc"],
        ]

        return subprocess.run(
            command,
            capture_output=True,
            text=True,
        )

    return run


@pytest.fixture(scope="session")
def grpcurl(
    grpc_config: Mapping[str, str],
) -> Callable[..., subprocess.CompletedProcess[str]]:
    """Session-scoped grpcurl runner."""
    return grpc_runner(grpc_config)


@pytest.mark.parametrize(
    "cert_name,expected_code",
    [
        ("admin", None),
        ("unknown", INTERNAL),
    ],
)
def test_control_plane_cert_behavior(
    grpcurl: Callable[..., subprocess.CompletedProcess[str]],
    grpc_config: Mapping[str, str],
    certs: Mapping[str, Any],
    cert_name: str,
    expected_code: str | None,
) -> None:
    cert, key = certs[cert_name]

    result = grpcurl(
        cacert=grpc_config["cacert"],
        cert=cert,
        key=key,
        endpoint=grpc_config["control_plane"],
    )

    if expected_code is None:
        assert result.stderr == ""
    else:
        assert extract_code(result.stderr) == expected_code


@pytest.mark.parametrize(
    "cert_name,expected_code",
    [
        ("admin", UNAUTHENTICATED),
        ("monitoring", None),
    ],
)
@pytest.mark.parametrize(
    "header,value",
    [
        ("X-Certificate-Client-CN", "invalid.cn"),
        ("X-Certificate-Client-Fingerprint", "123456789"),
    ],
)
def test_header_override_behavior(
    grpcurl: Callable[..., subprocess.CompletedProcess[str]],
    grpc_config: Mapping[str, str],
    certs: Mapping[str, Any],
    cert_name: str,
    expected_code: str | None,
    header: str,
    value: str,
) -> None:
    """
    A certificate that is not in the list of trusted common names is
    not allowed to override the headers. Inyecting
    invalid headers the request should succeed. If the certificate is not
    in the aforementioned list, the inyected headers are ignored and the
    request should succeed.
    """
    cert, key = certs[cert_name]

    result = grpcurl(
        cacert=grpc_config["cacert"],
        cert=cert,
        key=key,
        endpoint=grpc_config["control_plane"],
        headers=[f"{header}: {value}"],
    )

    if expected_code is None:
        assert result.stderr == ""
    else:
        assert extract_code(result.stderr) == expected_code


@pytest.mark.parametrize(
    "cert_name,expected_code",
    [
        ("admin", None),
        ("norole", UNAUTHENTICATED),
        ("unknown", INTERNAL),
    ],
)
def test_mcp_cert_behavior(
    grpcurl: Callable[..., subprocess.CompletedProcess[str]],
    grpc_config: Mapping[str, str],
    certs: Mapping[str, Any],
    cert_name: str,
    expected_code: str | None,
) -> None:
    cert, key = certs[cert_name]

    result = grpcurl(
        cacert=grpc_config["mcp_cacert"],
        cert=cert,
        key=key,
        endpoint=grpc_config["mcp"],
    )

    if expected_code is None:
        assert result.stderr == ""
    else:
        assert extract_code(result.stderr) == expected_code
