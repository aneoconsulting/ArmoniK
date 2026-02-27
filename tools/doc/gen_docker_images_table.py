import argparse
import requests

# URL to the versions.tfvars.json file
VERSIONS_JSON_URL = (
    "https://raw.githubusercontent.com/aneoconsulting/ArmoniK/main/versions.tfvars.json"
)


def fetch_versions_from_tfvars():
    """
    Fetch the versions.tfvars.json from GitHub and extract
    Docker image names and their versions.
    Images use the version from the armonik_versions object.
    Returns a dict mapping image names to their versions.
    """
    try:
        response = requests.get(VERSIONS_JSON_URL)
        response.raise_for_status()
        data = response.json()
    except requests.RequestException as e:
        print(f"Error fetching {VERSIONS_JSON_URL}: {e}")
        return {}, []

    armonik_versions = data.get("armonik_versions", {})
    armonik_images = data.get("armonik_images", {})

    images_and_versions = {}
    all_images = []

    # Process each category and its images
    for category, images_list in armonik_images.items():
        if isinstance(images_list, list):
            # Get the version for this category from armonik_versions
            category_version = armonik_versions.get(category, "Version not found")

            for image in images_list:
                # Skip non-docker image entries (like git repos)
                if image.startswith("dockerhubaneo") or image.startswith("docker"):
                    all_images.append(image)
                    images_and_versions[image] = category_version

    return images_and_versions, all_images


def create_rst_table(images, versions):
    """Return a reStructuredText list-table string for the given data."""
    lines = [
        ".. list-table::",
        "   :header-rows: 1",
        "",
        "   * - Image Name",
        "     - Last release version",
    ]

    for image in images:
        version = versions.get(image, "N/A")
        lines.append(f"   * - {image}")
        lines.append(f"     - {version}")

    return "\n".join(lines) + "\n"


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Generate Docker image versions table from versions.tfvars.json."
    )
    parser.add_argument(
        "-o",
        "--output",
        default="docker_images_table.rst",
        help="Path to write the generated table (defaults to docker_images_table.rst)",
    )
    args = parser.parse_args()

    versions, images = fetch_versions_from_tfvars()
    table_text = create_rst_table(images, versions)

    with open(args.output, "w", encoding="utf-8") as out_file:
        out_file.write(table_text)

    print(f"Wrote table to {args.output}")
