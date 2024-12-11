# Numerical experiments for ZODA: Zero-Overhead Data Availability

This repo contains the calculations for the numbers provided in
the tables for [ZODA: Zero-Overhead Data Availability](https://angeris.github.io/papers/da-construction.pdf).

## Running scripts
To run the main script (which is `total-comm.jl`) simply launch [Julia](https://julialang.org)
in this directory and run
```julia
julia> include("./total-comm.jl")

----- Data size: 32.000 MiB -----
[...]
```
which should print out all of the data used in the provided tables.

## Citation
To cite our work using BibTeX, please use the following format:
```
@article{evans2024zoda,
  title={{ZODA}: Zero-Overhead Data Availability},
  author={Evans, Alex and Mohnblatt, Nicolas and Angeris, Guillermo},
  year={2024},
  month={December},
  url={https://angeris.github.io/papers/da-construction.pdf},
}
```
