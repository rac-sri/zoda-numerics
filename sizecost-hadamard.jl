function compute_sizes(; C, lp, lpp, F, Fp, N, rate, n_ratio=1)
    # Number of field elements for data $N$ (where $N$ is given in bytes)
    num_field_data = 8*N/F

    # Side length of unencoded data square
    n = ceil(Int64, sqrt(num_field_data)*n_ratio)
    np = ceil(Int64, n/n_ratio^2)

    # Side length of complete square
    m = round(Int64, n/rate)

    # ---
    # Note that the following numbers can be heavily optimized by using the fact
    # that the openings are uniform, so much of each opening proof is repeated over
    # the elements
    # ---

    # Number of openings for sparsity check
    cS = ceil(Int64, -lpp/log2((1+rate)/2))
    if log2(m) - Fp >= 0
        @warn "Soundness error for proof is larger than 1."
    end
    cSp = ceil(Int64, lp/(Fp - log2(m)))

    # Size of opening for row of X or column of Y, assuming 2-ary Merkle tree, in
    # bits
    size_opening_X = C*ceil(Int64, log2(m))
    size_opening_Y = C*ceil(Int64, log2(m)) # XXX: Ignoring for now since this should be very small

    # Total size of commitment openings in bits
    total_opening_size = cS*size_opening_X

    # Total size for row of X or column of Y
    row_size = F*n
    col_size_extension = Fp*np

    # Total size of sent rows/cols of X/Y and field elements of Z in bits
    total_field_opening_size = cS*row_size + cSp*col_size_extension

    # Total proof size
    total_size = total_opening_size + total_field_opening_size

    total_size_bytes = ceil(Int64, total_size/8)

    current_celestia_bytes = ceil(Int64, (cS*F + 2*m*C)/8)


    # Soundness error over subspace distance check
    bits_sec = round(cSp*(Fp - log2(m)), digits=2)

    return (;
        total_size_bytes,
        current_celestia_bytes,
        bits_sec,
        cSp
    )
end

# ----- Inputs for calculation -----

# s = []
for logn in [23, 26, 28, 30, 38, 40]
# for logn in range(23, 40, length=100)
    smallest_size = Inf
    small_F, small_Fp, small_ratio = Inf, Inf, Inf
    @info "---- N = $(Base.format_bytes(2^logn)) ----"
    # for F in [1, 2, 4, 8, 16, 32]
    for F in [2, 4, 8, 16, 32]
        for Fp in [32, 64, 128]
            for n_ratio in [1]
                # Commitment size (in bits), assuming SHA256
                C = 256

                # Error probability (in bits) for subspace distance check
                lp = 80

                # Error probability (in bits) for sparsity check
                lpp = 80

                # Total data size (in bytes)
                N = 2^logn

                # Code rate, assuming RS
                rate = 1/4

                sizes = compute_sizes(; C, lp, lpp, F, Fp, N, rate, n_ratio)

                if smallest_size > sizes.total_size_bytes
                    smallest_size = sizes.total_size_bytes
                    small_F, small_Fp, small_ratio = F, Fp, n_ratio
                end
            end
        end
    end
    @info "Smallest found is F = $small_F, Fp = $small_Fp, n_ratio = $small_ratio"
    @info "Size = $(Base.format_bytes(smallest_size))"
end

