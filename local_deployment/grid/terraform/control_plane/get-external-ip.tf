data "external" "external_ip" {
    program = ["bash", "get_external_ip.sh"]
    working_dir = "./scripts_bash"
}