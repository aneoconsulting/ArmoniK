# Region
region = "us-west-2"

# Tags
tags = {
  Terraform   = "true"
  Environment = "dev"
}

# SSH key
ssh_key = {
  private_key_path = "~/.ssh/cluster-key"
  public_key       = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCeyb187cAe1ENdI0eUYQic5L7vFUj2CST2RM01DdMXrsiWHimoiWzrq4+roQADcTCXEqY/w3q3on63cRcjx+uc9gQJvp7B+BnDAqga3mBnxvGBdVdP/VGw55M2E9XynOWtQU+uHiUP1i+rJHY7lhkHbPyFOFxOL2fuMl3S9BEEF75GcX+Ug4hZxpc7bXdYLhSrpvSBI+Amj7RXTpaRK/5/RRkAXkNasYVby/6yyypHayxOZlbm2faHchTFKKFG5oKsCrKUR7v09htmDJDQ67y6Z2dxeEUygtN1D1s2bLa979dSH2grfV0WLq8TY1ZaPKOgR9D49XG+t1rnHgwPrJrP91k6YFqZ8yKbjsA5GyhEP8Uc2Ndhv/2tTKeUQBYP6rsDVuZ1f4RTtC6Vmz6rp0/xxpZsj6yczY9HEMw4voS7o6pJxGrXDa/cKrI6MS98dGLtcIjRPPetSPuvjRczCmU8+8chtdZzQFP0yorPIoQJVw7MExv0HhKTa88BcVSWedaRYmrBOX0a1CANlPMTci0Zft7FeAzX8+KhYccx1z20X6woPmmhev0RN7T6J+EKZLcynrNstDq2ruwWOBPZdSQg0XC4ngxorehjff5bTFCTJFHCb0HIq+QaDGtjYuV3sSJH2R3swo5Q77FohG/SvrZX1QXTPystpMtpds8550HKkw== sysadmin@ANEO-5B0QJR2"
}

# Number of workers
nb_workers = 3