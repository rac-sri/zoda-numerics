function compute_sizes(; C, lpp, F, F_extension, N, rate_row, rate_col)
    # Number of field elements for data $N$ (where $N$ is in bytes)
    num_field_data = 8*N/F

    # Side length of unencoded data square
    n = ceil(Int64, sqrt(num_field_data))

    # Side length of complete square
    m = round(Int64, n/rate_row)
    mp = round(Int64, n/rate_col)

    # ---
    # Note that the following numbers can be heavily optimized by using the fact
    # that the openings are uniform, so much of each opening proof is repeated over
    # the elements
    # ---

    # Number of openings for sparsity check
    cS = ceil(Int64, -lpp/log2((1+rate_row)/2))

    # Size of opening for row of X or column of Y, assuming 2-ary Merkle tree, in
    # bits
    size_opening_X = C*ceil(Int64, log2(m))
    size_opening_Y = C*ceil(Int64, log2(mp))

    # Size of opening for entries of Z
    size_opening_Z = size_opening_X + size_opening_Y

    # Total size of commitment openings (cS for X, 1 for Y, and cS for Z) in bits
    total_opening_size = cS*size_opening_X + size_opening_Y + cS*size_opening_Z

    # Total size for row of X or column of Y
    row_size = F*n
    col_size = F_extension*n

    # Total size of sent rows/cols of X/Y and field elements of Z in bits
    total_field_opening_size = cS*row_size + col_size + cS*F_extension

    # Total proof size
    total_size = total_opening_size + total_field_opening_size

    total_size_bytes = ceil(Int64, total_size/8)
    ultralight_size_bytes = ceil(Int64, cS*(size_opening_Z + F)/8)

    current_celestia_bytes = ceil(Int64, (cS*F + 2*m*C)/8)


    # Soundness error over subspace distance check
    bits_sec = round(F_extension - log2(2n), digits=2)

    # Total size of encoding
    total_size_enc_bytes = (m*mp*F + size_opening_X*m + size_opening_Y*mp)/8

    return (;
        total_size_bytes,
        ultralight_size_bytes,
        current_celestia_bytes,
        bits_sec,
        total_size_enc_bytes
    )
end

# ----- Inputs for calculation -----

# s = []
for logn in [23, 26, 28, 30, 38, 40]
# for logn in range(23, 40, length=100)
    @info "---- N = $(Base.format_bytes(2^logn)) ----"
    # Commitment size (in bits), assuming SHA256
    C = 256

    # Error probability (in bits) for subspace distance check
    lp = 80

    # Error probability (in bits) for sparsity check
    lpp = 7

    # Field size (in bits)
    # F = 8*512
    F = 8
    F_extension = 128

    # Total data size (in bytes)
    # N = 8*2^20
    # N = 2^30
    N = 2^logn

    # Code rate, assuming RS
    rate_row = 1/4
    rate_col = 1/2

    sizes = compute_sizes(; C, lpp, F, F_extension, N, rate_row, rate_col)

    if sizes.bits_sec ≥ lp
        #@info "Total number of bits of security over the noninteractive subspace distance check $(sizes.bits_sec) ≥ required bits $(lp)"
    else
        @warn "Parameters only guarantee $sizes.bits_sec bits of security which is less than the specified $lp bits; consider a larger field size"
    end


    @info "Total size: $(Base.format_bytes(sizes.total_size_bytes))"
    println()
end
