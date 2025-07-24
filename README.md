# Zoda Numerics - Proof System Comparison

This repository contains analysis and comparison of different distributed proof system approaches for matrix multiplication verification.

## Performance Comparison Table

| Data Size     | ZODA      | ZODA (Field Ext) | ZODA Hadamard | KZG       | Entrywise KZG | Row-wise AVAIL KZG | FRIDA         |
| ------------- | --------- | ---------------- | ------------- | --------- | ------------- | ------------------ | ------------- |
| **32 MiB**    |           |                  |               |           |               |                    |               |
| Nodes         | 16        | 61               | 197           | 22        | 17,455        | 17,477             | 35,546        |
| Per-node Cost | 8.67 MiB  | 1.24 MiB         | 572 KiB       | 12.34 MiB | 96.5 KiB      | 11.3 KiB           | 799 KiB       |
| Network Comm  | 138.7 MiB | 75.3 MiB         | 110.1 MiB     | 271.4 MiB | 1.61 GiB      | 192.8 MiB          | 27.08 GiB     |
| Overhead      | 4.34x     | 2.35x            | 3.44x         | 8.48x     | 51.39x        | 6.03x              | 866.66x       |
| **256 MiB**   |           |                  |               |           |               |                    |               |
| Nodes         | 43        | 170              | 556           | 60        | 139,633       | 139,811            | 284,360       |
| Per-node Cost | 24.28 MiB | 3.35 MiB         | 1.48 MiB      | 34.86 MiB | 239.8 KiB     | 11.3 KiB           | 1.01 MiB      |
| Network Comm  | 1.02 GiB  | 570.3 MiB        | 824.6 MiB     | 2.04 GiB  | 31.93 GiB     | 1.51 GiB           | 272.7 GiB     |
| Overhead      | 4.08x     | 2.23x            | 3.22x         | 8.17x     | 127.73x       | 6.03x              | 1090.64x      |
| **1 GiB**     |           |                  |               |           |               |                    |               |
| Nodes         | 86        | 340              | 1,111         | 119       | 558,528       | 559,242            | 1,137,439     |
| Per-node Cost | 48.42 MiB | 6.63 MiB         | 2.91 MiB      | 69.72 MiB | 461.5 KiB     | 11.3 KiB           | 1.10 MiB      |
| Network Comm  | 4.07 GiB  | 2.20 GiB         | 3.16 GiB      | 8.10 GiB  | 245.8 GiB     | 6.03 GiB           | 1.19 TiB      |
| Overhead      | 4.07x     | 2.20x            | 3.16x         | 8.10x     | 245.82x       | 6.03x              | 1218.73x      |
| **32 GiB**    |           |                  |               |           |               |                    |               |
| Nodes         | 481       | 1,922            | 6,284         | 670       | 17,872,857    | 17,895,698         | 36,398,029    |
| Per-node Cost | 273.1 MiB | 37.06 MiB        | 16.16 MiB     | 394.4 MiB | 2.47 MiB      | 11.3 KiB           | 1.47 MiB      |
| Network Comm  | 128.3 GiB | 69.55 GiB        | 99.17 GiB     | 258.0 GiB | 42.05 TiB     | 192.8 GiB          | 51.09 TiB     |
| Overhead      | 4.01x     | 2.17x            | 3.10x         | 8.06x     | 1345.68x      | 6.03x              | 1634.83x      |
| **1 TiB**     |           |                  |               |           |               |                    |               |
| Nodes         | 2,717     | 10,867           | 35,546        | 3,785     | 571,931,398   | 572,662,307        | 1,164,736,894 |
| Per-node Cost | 1.51 GiB  | 209.1 MiB        | 91.08 MiB     | 2.18 GiB  | 13.87 MiB     | 11.3 KiB           | 1.93 MiB      |
| Network Comm  | 4.00 TiB  | 2.17 TiB         | 3.09 TiB      | 8.05 TiB  | 7.39 PiB      | 6.03 TiB           | 2.10 PiB      |
| Overhead      | 4.00x     | 2.17x            | 3.09x         | 8.05x     | 7567.42x      | 6.03x              | 2146.92x      |

## Key Findings

### Best Performance

- **ZODA (Field Extension)** consistently achieves the lowest overhead (2.17-2.35x)
- **Row-wise AVAIL KZG** shows dramatic improvement over entrywise approach (6.03x vs 245-7567x overhead)

### Scalability Issues

- **Entrywise KZG** scales poorly with massive node requirements (17K to 572M nodes)
- **FRIDA** has high overhead but reasonable per-node costs

### Middle Ground

- **Standard KZG** provides balanced performance (8.05-8.48x overhead)
- **ZODA Hadamard** offers good trade-offs (3.09-3.44x overhead)

## Methodology

The analysis compares different approaches for distributed matrix multiplication verification:

1. **ZODA**: Original ZODA protocol
2. **ZODA (Field Extension)**: ZODA with field extension optimization
3. **ZODA Hadamard**: ZODA with Hadamard product optimization
4. **KZG**: Kate-Zaverucha-Goldberg commitments with row/column sampling
5. **Entrywise KZG**: KZG with individual element commitments
6. **Row-wise AVAIL KZG**: KZG with row-wise commitments (optimized)
7. **FRIDA**: FRIDA protocol implementation

## Running the Analysis

To reproduce these results:

```bash
julia total-comm.jl
```

This will generate the complete comparison across different data sizes and security parameters.

## Security Parameters

All results are computed with:

- **Security level**: 80 bits
- **Field size**: 384 bits (KZG), 128 bits (FRIDA)
- **Code rates**: Varies by protocol (1/2 to 3/4)
