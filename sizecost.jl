function num_samples(lpp, n_bad, n_total)
    total = 0.0
    for i in 0:(n_total - n_bad - 1)
        total += log2((n_total - i - n_bad)/(n_total - i))
        if total < -lpp
            return i+1
        end
    end
    return n_total - n_bad
end

function compute_sizes(; C, lpp, F, N, rate)
    # Number of field elements for data $N$ (in bytes)
    num_field_data = 8*N/F

    # Side length of unencoded data square
    n = ceil(Int64, sqrt(num_field_data))

    # Side length of complete square
    m = round(Int64, n/rate)

    # ---
    # Note that the following numbers can be heavily optimized by using the fact
    # that the openings are uniform, so much of each opening proof is repeated over
    # the elements
    # ---

    # Number of openings for sparsity check
    # cS = ceil(Int64, -lpp/log2((1+rate)/2))
    n_bad = ceil(Int64, (n+1)/2)
    cS = num_samples(lpp, n_bad, m)

    # Size of opening for row of X or column of Y, assuming 2-ary Merkle tree, in
    # bits
    size_opening = C*ceil(Int64, log2(m))

    # Size of opening for entries of Z
    size_opening_Z = 2*size_opening

    # Total size of commitment openings (cS for X, cS for Y, and cS^2 for Z) in bits
    total_opening_size = 2*cS*size_opening + cS^2*size_opening_Z

    # Total size for row of X or column of Y
    row_col_size = F*n

    # Total size of sent rows/cols of X/Y and field elements of Z in bits
    total_field_opening_size = 2*cS*row_col_size + cS^2*F

    # Total proof size
    total_size = total_opening_size + total_field_opening_size

    total_size_bytes = ceil(Int64, total_size/8)
    # ultralight_size_bytes = ceil(Int64, cS*(size_opening_Z + F)/8)

    # current_celestia_bytes = ceil(Int64, (cS*F + 2*m*C)/8)


    # Soundness error over subspace distance check
    bits_sec = round(F - log2(2n), digits=2)

    return (;
        total_size_bytes,
    #    ultralight_size_bytes,
    #    current_celestia_bytes,
        bits_sec
    )
end

# ----- Inputs for calculation -----

# s = []
#for logn in [23, 25, 27, 29, 31, 33]
# for lpp in [7, 20, 40, 80]
for lpp in [80]
    @info "---- lpp = $lpp ----"
    for logn in [23, 26, 28, 30, 38, 40]
    # for logn in range(23, 40, length=100)
        @info "---- N = $(Base.format_bytes(2^logn)) ----"
        # Commitment size (in bits), assuming SHA256
        C = 256

        # Error probability (in bits) for subspace distance check
        lp = 80

        # Error probability (in bits) for sparsity check
        # lpp = 21

        # Field size (in bits)
        # F = 8*512
        F = 128

        # Total data size (in bytes)
        # N = 8*2^20
        # N = 2^30
        N = 2^logn

        # Code rate, assuming RS
        rate = 1/2

        sizes = compute_sizes(; C, lpp, F, N, rate)

        if sizes.bits_sec ≥ lp
            #@info "Total number of bits of security over the noninteractive subspace distance check $(sizes.bits_sec) ≥ required bits $(lp)"
        else
            @warn "Parameters only guarantee $sizes.bits_sec bits of security which is less than the specified $lp bits; consider a larger field size"
        end


        @info "Total size: $(Base.format_bytes(sizes.total_size_bytes))"
        # push!(s, sizes.total_size_bytes)
        #@info "Total size for ultralight nodes, including openings: $(Base.format_bytes(sizes.ultralight_size_bytes))"
        #@info "Total size for light nodes in current setting: $(Base.format_bytes(sizes.current_celestia_bytes))"
        #println()
    end
    println()
end
