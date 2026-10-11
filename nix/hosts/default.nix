{ inputs }:

{
  LCDEV0215 = import ./LCDEV0215 { inherit inputs; };
  "mba13-m3-2024-01" = import ./mba13-m3-2024-01 { inherit inputs; };
}
