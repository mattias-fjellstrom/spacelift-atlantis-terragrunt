include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../modules/random-number"
}

inputs = {
  min     = 10
  max     = 1000
}