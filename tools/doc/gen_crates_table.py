import requests
import argparse


def search_rust_crates(search_term):
    url = f"https://crates.io/api/v1/crates?q={search_term}"
    response = requests.get(url)

    if response.status_code == 200:
        data = response.json()
        crates = data.get("crates", [])
        return [(crate["name"], crate["default_version"]) for crate in crates]
    else:
        print(f"Error fetching Rust crates: {response.status_code}")
        return []


def create_rust_rst_table(crates):
    if not crates:
        return ".. list-table::\n   :header-rows: 1\n\n   * - No crates found."

    table = ".. list-table::\n   :header-rows: 1\n\n   * - Crate Name\n     - Default Version\n"

    for crate in crates:
        table += f"   * - {crate[0]}\n     - {crate[1]}\n"

    return table


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Generate Rust crate versions table.")
    parser.add_argument(
        "-o",
        "--output",
        default="rust_crates_table.rst",
        help="Path to write the generated table (defaults to rust_crates_table.rst)",
    )
    parser.add_argument(
        "-s",
        "--search",
        default="armonik",
        help="Search term for Rust crates (defaults to 'armonik')",
    )

    args = parser.parse_args()

    crates = search_rust_crates(args.search)
    rst_table = create_rust_rst_table(crates)

    with open(args.output, "w", encoding="utf-8") as out_file:
        out_file.write(rst_table)

    print(f"Wrote table to {args.output}")
