import requests
import argparse


def search_nuget_packages(search_term):
    url = f"https://azuresearch-ussc.nuget.org/query?q={search_term}&prerelease=false&semVerLevel=2.0.0"
    response = requests.get(url)

    if response.status_code == 200:
        data = response.json()
        packages = data.get("data", [])
        return [(pkg["id"], pkg["version"]) for pkg in packages]
    else:
        print(f"Error fetching NuGet packages: {response.status_code}")
        return []


def create_nuget_rst_table(packages):
    if not packages:
        return ".. list-table::\n   :header-rows: 1\n\n   * - No packages found."

    table = ".. list-table::\n   :header-rows: 1\n\n   * - Package Name\n     - Last release version\n"

    for pkg in packages:
        table += f"   * - {pkg[0]}\n     - {pkg[1]}\n"

    return table


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Generate NuGet package versions table."
    )
    parser.add_argument(
        "-o",
        "--output",
        default="nuget_packages_table.rst",
        help="Path to write the generated table (defaults to nuget_packages_table.rst)",
    )
    parser.add_argument(
        "-s",
        "--search",
        default="armonik",
        help="Search term for NuGet packages (defaults to 'armonik')",
    )

    args = parser.parse_args()

    packages = search_nuget_packages(args.search)
    rst_table = create_nuget_rst_table(packages)

    with open(args.output, "w", encoding="utf-8") as out_file:
        out_file.write(rst_table)

    print(f"Wrote table to {args.output}")
