# Number of nodes needed to guarantee that there are enough samples to
# reconstruct something (assuming MDS code)
function n_nodes(n, rate, n_samples, log_prob; m=nothing)
    if isnothing(m)
        m = ceil(n / rate)
    end

    # For now, use simple approximation
    # ceil(Int, required_symbols / (effective_samples_per_node))
    return ceil(Int, (log_prob + m) / (log(2, 1 / rate) * n_samples))
end

# Total communication across the network
function total_comm(n, rate, commit_size, symbol_size, n_samples, log_prob; m=nothing)
    num_nodes = n_nodes(n, rate, n_samples, log_prob; m)
    return (num_nodes, num_nodes * (n_samples * symbol_size + commit_size))
end

# Taken from calculations used in the FRIDA paper (for the interactive portion)
# MiB => MiB
frida_comm_size_map = Dict(
    32 => 0.3909912109375,
    256 => 0.4918212890625,
    1024 => 0.549468994140625,
    8192 => 0.69354248046875,
    32768 => 0.73675537109375,
    262144 => 0.880828857421875,
    1048576 => 0.967254638671875,
)

# MiB => KiB
frida_symbol_size_map = Dict(
    32 => 3.3775634765625,
    256 => 4.2525634765625,
    1024 => 4.7530517578125,
    8192 => 6.0035400390625,
    32768 => 6.3785400390625,
    262144 => 7.6290283203125,
    1048576 => 8.3790283203125,
)

N_list = 8 .* (2 .^ [25, 28, 30, 35, 40])

# N = 2^30 * 8 # 1 GiB
for N in N_list
    println("\n----- Data size: $(Base.format_bytes(N/8)) -----\n")

    # N = 2^25 * 8
    log_prob = 40 # Probability of collecting samples
    log_node_soundness = 80 # Soundness error for nodes

    println("----- ZODA -----")
    field_size_zoda = 128
    n_zoda = ceil(Int, sqrt(N / field_size_zoda))
    rate_zoda = 1 / 2
    opening_size_zoda = ceil(Int, log2(n_zoda/rate_zoda)*256)

    commit_size_zoda = 2*256 # Negligible, two Merkle headers
    symbol_size_zoda = 2 * (field_size_zoda * n_zoda + opening_size_zoda)

    n_samples_zoda = ceil(Int, -log_node_soundness / log2((1 + rate_zoda) / 2))
    println("Per node cost: $(Base.format_bytes((commit_size_zoda + n_samples_zoda*symbol_size_zoda)/8))")

    n_nodes_zoda, total_comm_zoda = total_comm(
        n_zoda,
        rate_zoda,
        commit_size_zoda,
        symbol_size_zoda,
        n_samples_zoda,
        log_prob
    )

    println("Number of $(log_node_soundness) bits nodes needed for ZODA: $n_nodes_zoda")
    println("Total network communication for ZODA: $(Base.format_bytes(total_comm_zoda/8))")
    println("Total network overhead for ZODA: $(round(total_comm_zoda/N, digits=2))x")

    println("----- ZODA (Field extension) -----")
    field_size_zoda_e = 8
    field_size_zoda_ext = 128
    n_zoda_e = ceil(Int, sqrt(N / field_size_zoda_e))
    rate_zoda_e = 1 / 2
    opening_size_zoda_e = ceil(Int, log2(n_zoda_e/rate_zoda_e)*256)

    commit_size_zoda_e = 2*256 + field_size_zoda_ext*n_zoda_e + opening_size_zoda_e
    symbol_size_zoda_e = field_size_zoda_e * n_zoda_e +  opening_size_zoda_e

    n_samples_zoda_e = ceil(Int, -log_node_soundness / log2((1 + rate_zoda_e) / 2))
    println("Per node cost: $(Base.format_bytes((commit_size_zoda_e + n_samples_zoda*symbol_size_zoda_e)/8))")

    n_nodes_zoda_e, total_comm_zoda_e = total_comm(
        n_zoda_e,
        rate_zoda_e,
        commit_size_zoda_e,
        symbol_size_zoda_e,
        n_samples_zoda_e,
        log_prob
    )

    println("Number of $(log_node_soundness) bits nodes needed for ZODA (Field ext): $n_nodes_zoda_e")
    println("Total network communication for ZODA (Field ext): $(Base.format_bytes(total_comm_zoda_e/8))")
    println("Total network overhead for ZODA (Field ext): $(round(total_comm_zoda_e/N, digits=2))x")


    println("----- ZODA Hadamard -----")
    field_size_had = 2
    field_ext_had = 64
    n_had = ceil(Int, sqrt(N / field_size_had))
    rate_had = 1 / 4
    opening_size_had = ceil(Int, log2(n_had/rate_had)*256)

    commit_size_had = 2*256 + 2*n_had*field_ext_had
    symbol_size_had = field_size_had * n_had + opening_size_had

    n_samples_had = ceil(Int, -log_node_soundness / log2((1 + rate_had) / 2))
    println("Per node cost: $(Base.format_bytes((commit_size_had + n_samples_had*symbol_size_had)/8))")

    n_nodes_had, total_comm_had = total_comm(
        n_had,
        rate_had,
        commit_size_had,
        symbol_size_had,
        n_samples_had,
        log_prob
    )

    println("Number of $(log_node_soundness) bits nodes needed for ZODA Hadamard: $n_nodes_had")
    println("Total network communication for ZODA Hadamard: $(Base.format_bytes(total_comm_had/8))")
    println("Total network overhead for ZODA Hadamard: $(round(total_comm_had/N, digits=2))x")

    # --- KZG sampling per row/col ---
    println("----- KZG -----")

    field_size_kzg = 384
    group_size_kzg = field_size_kzg

    n_kzg = ceil(Int, sqrt(N / field_size_kzg))
    rate_kzg = 1 / 2

    commit_size_kzg = group_size_kzg * n_kzg * 2
    symbol_size_kzg = 2 * (field_size_kzg + group_size_kzg) * n_kzg

    # (1/2)^n_samples <= 2^(-log_node_soundness) means log_node_soundness samples
    # suffices to reconstruct anything
    n_samples_kzg = log_node_soundness
    println("Per node cost: $(Base.format_bytes((commit_size_kzg + n_samples_kzg*symbol_size_kzg)/8))")
    # commit_size_kzg = 2*n_samples_kzg*group_size_kzg

    n_nodes_kzg, total_comm_kzg = total_comm(
        n_kzg,
        rate_kzg,
        commit_size_kzg,
        symbol_size_kzg,
        n_samples_kzg,
        log_prob
    )

    println("Number of $(log_node_soundness) bits nodes needed for KZG: $n_nodes_kzg")
    println("Total network communication for KZG: $(Base.format_bytes(total_comm_kzg/8))")
    println("Total network overhead for KZG: $(round(total_comm_kzg/N, digits=2))x")

    # --- Entrywise KZG ---
    println("----- Entrywise KZG -----")

    n_kzg_e = N/field_size_kzg
    sidelength_kzg_e = sqrt(n_kzg_e)
    # Trivial decoder requires 
    rate_kzg_e = 3 / 4

    commit_size_kzg_e = group_size_kzg * sidelength_kzg_e * 2
    symbol_size_kzg_e = field_size_kzg + group_size_kzg

    n_samples_kzg_e = ceil(Int, -log_node_soundness / log2(rate_kzg_e))
    println("Per node cost: $(Base.format_bytes((commit_size_kzg_e + n_samples_kzg_e*symbol_size_kzg_e)/8))")

  
    per_commitment_cost = group_size_kzg  # 384 bits per commitment
    println("(Internal reference) Per-commitment cost: $(Base.format_bytes(per_commitment_cost/8))")

    # Per-row cost (total commitment size for a row)
    per_row_cost = group_size_kzg * sidelength_kzg_e  # 384 * sqrt(n_kzg_e) bits per row
    println("(Internal reference) Per-row cost: $(Base.format_bytes(per_row_cost/8))")

    # Total commitment size to be downloaded
    total_commitment_size = n_kzg_e * per_commitment_cost  # Total bits for all commitments
    println("(Internal reference) Total commitment size to download: $(Base.format_bytes(total_commitment_size/8))")
  

    n_nodes_kzg_e, total_comm_kzg_e = total_comm(
        n_kzg_e,
        rate_kzg_e,
        commit_size_kzg_e,
        symbol_size_kzg_e,
        n_samples_kzg_e,
        log_prob;
        m=n_kzg_e/rate_kzg
    )

    println("Number of $(log_node_soundness) bits nodes needed for entrywise KZG: $n_nodes_kzg_e")
    println("Total network communication for entrywise KZG: $(Base.format_bytes(total_comm_kzg_e/8))")
    println("Total network overhead for entrywise KZG: $(round(total_comm_kzg_e/N, digits=2))x")

    
    # --- Row-wise AVAIL KZG ---
     println("----- Row-wise AVAIL KZG -----")

     n_kzg_e = N/field_size_kzg
     sidelength_kzg_e = sqrt(n_kzg_e)

     # Trivial decoder requires 
     rate_kzg_e = 1 / 2
 
     commit_size_kzg_e = group_size_kzg * sidelength_kzg_e # only rows
     symbol_size_kzg_e = 80
 
     n_samples_kzg_e = ceil(Int, -log_node_soundness / log2(rate_kzg_e))
     println("Per node cost: $(Base.format_bytes((commit_size_kzg_e + n_samples_kzg_e*symbol_size_kzg_e)/8))")
 
     println("(Internal reference) Per-commitment cost (row): $(Base.format_bytes(commit_size_kzg_e/8))")
 
     # Total commitment size to be downloaded (for both X and Y matrices)
     total_commitment_size = sidelength_kzg_e * per_commitment_cost  # 2 matrices * n_kzg_e rows each
     println("(Internal reference) Total commitment size to download: $(Base.format_bytes(total_commitment_size/8))")
 
  
     # Number of nodes calculation changes:
     # Instead of n_kzg_e individual entries, we have sidelength_kzg_e rows
     n_nodes_kzg_e, total_comm_kzg_e = total_comm(
         n_kzg_e, 
         rate_kzg_e,
         commit_size_kzg_e,
         symbol_size_kzg_e,
         n_samples_kzg_e,
         log_prob;
         m=n_kzg_e/rate_kzg # this remains n_kzg_e/rate_kzg because we still have to individual element
     )
 
     println("Number of $(log_node_soundness) bits nodes needed for row-wise KZG: $n_nodes_kzg_e")
     println("Total network communication for row-wise KZG: $(Base.format_bytes(total_comm_kzg_e/8))")
     println("Total network overhead for row-wise KZG: $(round(total_comm_kzg_e/N, digits=2))x")

     
    # --- FRIDA ---
    println("----- FRIDA -----")

    field_size_frida = 128
    n_frida = N / field_size_frida
    rate_frida = 1 / 4
    block_mib = div(N, 8 * 2^20)

    commit_size_frida = frida_comm_size_map[block_mib] * 2^20 * 8
    symbol_size_frida = frida_symbol_size_map[block_mib] * 2^10 * 8

    n_samples_frida = ceil(Int, -log((1+rate_frida)/2, 2) * log_node_soundness)
    println("Per-node cost: $(Base.format_bytes((commit_size_frida + n_samples_frida*symbol_size_frida)/8))")

    n_nodes_frida, total_comm_frida = total_comm(
        n_frida,
        rate_frida,
        commit_size_frida,
        symbol_size_frida,
        n_samples_frida,
        log_prob
    )

    println("Number of $(log_node_soundness) bits nodes needed for FRIDA: $n_nodes_frida")
    println("Total network communication for FRIDA: $(Base.format_bytes(total_comm_frida/8))")
    println("Total network overhead for FRIDA: $(round(total_comm_frida/N, digits=3))x")

end
