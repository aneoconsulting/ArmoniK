import requests
import argparse


def search_npm_packages(search_term):
    url = f"https://registry.npmjs.org/-/v1/search?text={search_term}&size=20"
    response = requests.get(url)

    if response.status_code == 200:
        data = response.json()
        packages = data.get("objects", [])
        return [(pkg["package"]["name"], pkg["package"]["version"]) for pkg in packages]
    else:
        print(f"Error fetching NPM packages: {response.status_code}")
        return []


def create_npm_rst_table(packages):
    if not packages:
        return ".. list-table::\n   :header-rows: 1\n\n   * - No packages found."

    table = ".. list-table::\n   :header-rows: 1\n\n   * - Package Name\n     - Latest Version\n"

    for pkg in packages:
        table += f"   * - {pkg[0]}\n     - {pkg[1]}\n"

    return table


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Generate NPM package versions table.")
    parser.add_argument(
        "-o",
        "--output",
        default="npm_packages_table.rst",
        help="Path to write the generated table (defaults to npm_packages_table.rst)",
    )
    parser.add_argument(
        "-s",
        "--search",
        default="armonik.api",
        help="Search term for NPM packages (defaults to 'armonik.api')",
    )

    args = parser.parse_args()

    packages = search_npm_packages(args.search)
    rst_table = create_npm_rst_table(packages)

    with open(args.output, "w", encoding="utf-8") as out_file:
        out_file.write(rst_table)

    print(f"Wrote table to {args.output}")
