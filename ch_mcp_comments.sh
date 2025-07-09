#!/bin/bash

# Multi-network database and table comments update script

# =============================================
# CONFIGURATION VARIABLES
# =============================================

# All available networks
ALL_NETWORKS=("arbitrum-one" "avalanche" "base" "bsc" "mainnet" "matic" "optimism" "unichain" "solana")

# Parse command line arguments for network selection
if [ $# -eq 0 ]; then
    # Default to all networks if no arguments provided
    NETWORKS=("${ALL_NETWORKS[@]}")
    connection_args=()
else
    # Determine which networks to process
    NETWORKS=()
    connection_args=()
    for arg in "$@"; do
        if [[ " ${ALL_NETWORKS[*]} " =~ " ${arg} " ]]; then
            NETWORKS+=("$arg")
        elif [ "$arg" = "all" ]; then
            NETWORKS=("${ALL_NETWORKS[@]}")
        else
            # Assume remaining arguments are connection parameters
            connection_args+=("$arg")
        fi
    done

    # If no valid networks specified but arguments were provided, use all networks
    # This handles cases like "./script.sh localhost 9000" (connection params only)
    if [ ${#NETWORKS[@]} -eq 0 ] && [ ${#connection_args[@]} -gt 0 ]; then
        NETWORKS=("${ALL_NETWORKS[@]}")
    fi
fi

# Database versions by category
TOKENS_VERSION_CURRENT="evm-tokens@v1.14.0"
TOKENS_VERSION_LEGACY="evm-tokens@v1.11.0:db_out"
NFT_VERSION_CURRENT="evm-nft-tokens@v0.5.1"
NFT_VERSION_LEGACY="evm-nft-tokens@v0.5.0"
UNISWAP_VERSION="evm-uniswaps@v0.1.5"
CONTRACTS_VERSION="evm-contracts@v0.3.1"
SOLANA_DEX_VERSION="solana-dex@v0.2.0"
SOLANA_TOKENS_VERSION="solana-tokens@v0.1.0"

# ClickHouse connection parameters (can be overridden by environment variables or remaining script arguments)
CH_HOST="${CH_HOST:-${connection_args[0]:-localhost}}"
CH_PORT="${CH_PORT:-${connection_args[1]:-9000}}"
CH_USER="${CH_USER:-${connection_args[2]:-default}}"
CH_PASSWORD="${CH_PASSWORD:-${connection_args[3]:-default}}"

# Build ClickHouse client command
CH_CLIENT="clickhouse client --host=${CH_HOST} --port=${CH_PORT} --user=${CH_USER} --password=${CH_PASSWORD}"

echo "ClickHouse connection settings:"
echo "  Host: ${CH_HOST}"
echo "  Port: ${CH_PORT}"
echo "  User: ${CH_USER}"
echo "  Password: [hidden]"
echo ""

# =============================================
# UTILITY FUNCTIONS
# =============================================

# Function to check if database exists
check_database_exists() {
    local network=$1
    local version=$2
    local db_name="${network}:${version}"
    
    local exists=$(${CH_CLIENT} --query "SELECT count() FROM system.databases WHERE name = '${db_name}'" 2>/dev/null || echo "0")
    echo $exists
}

# Function to check if table exists
check_table_exists() {
    local network=$1
    local version=$2
    local table=$3
    local db_name="${network}:${version}"
    
    local exists=$(${CH_CLIENT} --query "SELECT count() FROM system.tables WHERE database = '${db_name}' AND name = '${table}'" 2>/dev/null || echo "0")
    echo $exists
}

# Function to execute ALTER statement with error handling
execute_alter() {
    local network=$1
    local version=$2
    local table=$3
    local comment=$4
    local db_name="${network}:${version}"
    
    echo "Checking ${db_name}.${table}..."
    
    # Check if database exists
    if [ "$(check_database_exists $network $version)" -eq 0 ]; then
        echo "  ⚠️  Database ${db_name} does not exist, skipping..."
        return
    fi
    
    # Check if table exists
    if [ "$(check_table_exists $network $version $table)" -eq 0 ]; then
        echo "  ⚠️  Table ${db_name}.${table} does not exist, skipping..."
        return
    fi
    
    # Execute ALTER statement
    echo "  ✅ Updating comment for ${db_name}.${table}"
    if ${CH_CLIENT} --query "ALTER TABLE \`${db_name}\`.${table} ON CLUSTER '{cluster}' MODIFY COMMENT '${comment}'" 2>/dev/null; then
        echo "  ✅ Successfully updated ${db_name}.${table}"
    else
        echo "  ❌ Failed to update ${db_name}.${table}"
    fi
}

# Function to execute DATABASE ALTER statement with error handling
execute_database_alter() {
    local network=$1
    local version=$2
    local comment=$3
    local db_name="${network}:${version}"
    
    echo "Checking database ${db_name}..."
    
    # Check if database exists
    if [ "$(check_database_exists $network $version)" -eq 0 ]; then
        echo "  ⚠️  Database ${db_name} does not exist, skipping..."
        return
    fi
    
    # Execute ALTER DATABASE statement
    echo "  ✅ Updating comment for database ${db_name}"
    if ${CH_CLIENT} --query "ALTER DATABASE \`${db_name}\` ON CLUSTER '{cluster}' MODIFY COMMENT '${comment}'" 2>/dev/null; then
        echo "  ✅ Successfully updated database ${db_name}"
    else
        echo "  ❌ Failed to update database ${db_name}"
    fi
}

echo "Starting multi-network database and table comments update..."
echo "Selected networks: ${NETWORKS[*]}"
echo "========================================"

# =============================================
# DATABASE COMMENTS
# =============================================

echo ""
echo "Processing Database Comments..."
echo "----------------------------------------"

# Database comments for each network
for network in "${NETWORKS[@]}"; do
    echo ""
    echo "Processing database comments for network: ${network}"
    
    case $network in
        "arbitrum-one")
            execute_database_alter "$network" "$NFT_VERSION_CURRENT" "Arbitrum One NFT database containing ERC721/ERC1155 transfers, metadata, ownership, and marketplace activity data. Supports Layer 2 NFT market analysis, gaming asset tracking, and cross-chain NFT ecosystem research."
            execute_database_alter "$network" "$TOKENS_VERSION_LEGACY" "Legacy Arbitrum One token database (v1.11.0) with historical ERC20 transfer and balance data. Provides historical token flow analysis and migration reference data for protocol evolution research."
            execute_database_alter "$network" "$TOKENS_VERSION_CURRENT" "Latest Arbitrum One token database (v1.14.0) with comprehensive ERC20 transfers, native ETH transactions, balances, and metadata. Enables real-time DeFi analytics, portfolio tracking, and Layer 2 scaling effectiveness analysis."
            execute_database_alter "$network" "$UNISWAP_VERSION" "Arbitrum One Uniswap database with V2/V3/V4 swap data, liquidity events, pool creation, and price information. Supports DEX trading analysis, arbitrage opportunity detection, and Layer 2 liquidity migration research."
            ;;
        "avalanche")
            execute_database_alter "$network" "$NFT_VERSION_CURRENT" "Avalanche C-Chain NFT database containing ERC721/ERC1155 transfers, metadata, ownership, and marketplace transaction data. Enables gaming asset analysis, metaverse economy research, and high-throughput NFT ecosystem studies."
            execute_database_alter "$network" "$TOKENS_VERSION_CURRENT" "Latest Avalanche C-Chain token database (v1.14.0) with AVAX native transfers, ERC20 token activity, balances, and metadata. Supports subnet tokenomics analysis, fast-finality blockchain research, and cross-chain asset flow tracking."
            execute_database_alter "$network" "$UNISWAP_VERSION" "Avalanche Uniswap and DEX database with swap data, liquidity events, and integration with TraderJoe and Pangolin protocols. Provides DeFi ecosystem analytics, yield farming research, and Avalanche trading activity analysis."
            ;;
        "base")
            execute_database_alter "$network" "$NFT_VERSION_CURRENT" "Base Layer 2 NFT database containing ERC721/ERC1155 transfers, metadata, ownership, and marketplace data from Coinbase Base network. Supports creator economy analytics, social token research, and emerging Base NFT ecosystem analysis."
            execute_database_alter "$network" "$TOKENS_VERSION_LEGACY" "Legacy Base network token database (v1.11.0) with historical ERC20 and native ETH transfer data. Provides migration reference data and historical Base network scaling analysis during rapid protocol development."
            execute_database_alter "$network" "$TOKENS_VERSION_CURRENT" "Latest Base network token database (v1.14.0) with comprehensive ETH L2 transfers, ERC20 tokens, balances, and gas optimization data. Enables Base ecosystem growth analysis, user adoption tracking, and Layer 2 scaling effectiveness research."
            execute_database_alter "$network" "$UNISWAP_VERSION" "Base network Uniswap database with V3 deployment data, swap transactions, liquidity events, and low-fee trading patterns. Supports retail adoption analysis, Base-specific DEX innovation research, and Layer 2 trading behavior studies."
            ;;
        "bsc")
            execute_database_alter "$network" "$NFT_VERSION_CURRENT" "Binance Smart Chain NFT database containing ERC721/ERC1155 transfers, metadata, marketplace data, and cross-chain bridge activity. Supports high-volume NFT trading analysis, gaming asset economics research, and BNB-based collection studies."
            execute_database_alter "$network" "$TOKENS_VERSION_LEGACY" "Legacy BSC token database (v1.11.0) with historical BNB and BEP20 token transfer data from the DeFi boom period. Provides early yield farming protocol analysis and BSC ecosystem evolution research."
            execute_database_alter "$network" "$TOKENS_VERSION_CURRENT" "Latest BSC token database (v1.14.0) with comprehensive BNB native transfers, BEP20 tokens, staking rewards, and balance data. Enables high-volume transaction analysis, staking economics research, and largest EVM blockchain activity studies."
            execute_database_alter "$network" "$UNISWAP_VERSION" "BSC DEX ecosystem database with PancakeSwap, Venus, and AMM protocol data including swaps, liquidity events, and yield farming. Supports high-frequency trading analysis, DeFi yield research, and low-cost trading environment studies."
            ;;
        "mainnet")
            execute_database_alter "$network" "$CONTRACTS_VERSION" "Ethereum mainnet smart contract registry database with deployment data, verification status, and contract metadata. Supports protocol analysis, security research, and comprehensive Ethereum ecosystem mapping studies."
            execute_database_alter "$network" "$NFT_VERSION_LEGACY" "Legacy Ethereum mainnet NFT database (v0.5.1) with comprehensive marketplace data, metadata, and Seaport protocol integration. Enables blue-chip NFT analysis, market intelligence research, and creator economy tracking."
            execute_database_alter "$network" "$NFT_VERSION_CURRENT" "Latest Ethereum mainnet NFT database (v0.6.2) with enhanced metadata resolution, spam detection, and advanced marketplace analytics. Supports royalty tracking analysis, creator economy insights, and NFT market quality assessment."
            execute_database_alter "$network" "$TOKENS_VERSION_LEGACY" "Legacy Ethereum mainnet token database (v1.11.0) with historical ERC20 transfers and early DeFi protocol data. Provides longitudinal Ethereum ecosystem analysis and token evolution research."
            execute_database_alter "$network" "$TOKENS_VERSION_CURRENT" "Latest Ethereum mainnet token database (v1.14.0) with comprehensive ERC20 transfers, ETH native transactions, balances, and metadata. Enables real-time tokenomics analysis, DeFi research, and portfolio tracking."
            execute_database_alter "$network" "$UNISWAP_VERSION" "Ethereum mainnet Uniswap database with V2/V3/V4 protocol data, liquidity mining, fee analysis, and MEV detection capabilities. Supports DeFi research, trading analytics, and decentralized exchange ecosystem studies."
            ;;
        "matic")
            execute_database_alter "$network" "$NFT_VERSION_CURRENT" "Polygon (MATIC) NFT database containing ERC721/ERC1155 transfers, metadata, gaming assets, and metaverse token data. Enables play-to-earn game analysis, digital asset economy research, and high-throughput NFT ecosystem studies."
            execute_database_alter "$network" "$TOKENS_VERSION_LEGACY" "Legacy Polygon token database (v1.11.0) with historical MATIC and ERC20 token transfer data. Provides early Layer 2 adoption analysis and Polygon network scaling solution research."
            execute_database_alter "$network" "$TOKENS_VERSION_CURRENT" "Latest Polygon token database (v1.14.0) with comprehensive MATIC staking, ERC20 transfers, bridge activity, and balance data. Supports Layer 2 scaling analysis, multi-chain asset tracking, and staking economics research."
            execute_database_alter "$network" "$UNISWAP_VERSION" "Polygon DEX ecosystem database with Uniswap V3, QuickSwap, and SushiSwap deployment data including swaps and liquidity events. Enables high-speed trading analysis, yield farming research, and Layer 2 DeFi ecosystem studies."
            ;;
        "optimism")
            execute_database_alter "$network" "$NFT_VERSION_CURRENT" "Optimism Layer 2 NFT database containing ERC721/ERC1155 transfers, metadata, and reduced gas cost NFT applications. Supports L2 NFT adoption analysis, cross-layer bridge research, and optimistic rollup NFT ecosystem studies."
            execute_database_alter "$network" "$TOKENS_VERSION_LEGACY" "Legacy Optimism token database (v1.11.0) with early optimistic rollup token transfers and OP token distribution data. Provides Layer 2 scaling research and historical tokenomics analysis."
            execute_database_alter "$network" "$TOKENS_VERSION_CURRENT" "Latest Optimism token database (v1.14.0) with comprehensive OP governance tokens, ETH L2 transfers, and ecosystem incentive data. Enables Layer 2 adoption analysis, decentralized governance research, and scaling effectiveness studies."
            execute_database_alter "$network" "$UNISWAP_VERSION" "Optimism Uniswap database with V3 deployment data, Layer 2 optimization analytics, and retroactive funding impact data. Supports sustainable Layer 2 DEX research, funding mechanism analysis, and optimistic rollup trading studies."
            ;;
        "unichain")
            execute_database_alter "$network" "$NFT_VERSION_LEGACY" "Legacy Unichain NFT database (v0.5.1) with native DEX integration, specialized NFT-DeFi composability, and protocol optimization features. Enables protocol-owned blockchain innovation analysis and NFT-DeFi integration research."
            execute_database_alter "$network" "$NFT_VERSION_CURRENT" "Current Unichain NFT database (v0.6.2) with enhanced metadata resolution, spam detection, and native protocol optimizations. Supports purpose-built NFT ecosystem analysis and protocol innovation research."
            execute_database_alter "$network" "$TOKENS_VERSION_LEGACY" "Legacy Unichain token database (v1.11.0) with early network deployment and foundational token distribution data. Provides purpose-built blockchain analysis and governance token mechanism research."
            execute_database_alter "$network" "$TOKENS_VERSION_CURRENT" "Latest Unichain token database (v1.14.0) with native UNI integration, optimized swap routing, and protocol-specific tokenomics. Supports vertically-integrated DeFi analysis, native token research, and purpose-built blockchain performance studies."
            execute_database_alter "$network" "$UNISWAP_VERSION" "Unichain native DEX database with protocol-optimized trading, reduced MEV, enhanced liquidity provision, and native integration features. Enables purpose-built DEX blockchain research, MEV reduction analysis, and vertically-integrated protocol studies."
            ;;
        "solana")
            execute_database_alter "$network" "$SOLANA_DEX_VERSION" "Solana DEX database containing comprehensive swap data, liquidity events, and AMM protocol interactions across major Solana DEXs including Raydium. Supports high-throughput DeFi analysis, MEV research, and Solana ecosystem trading behavior studies."
            execute_database_alter "$network" "$SOLANA_TOKENS_VERSION" "Solana tokens database with SPL token transfers, mint operations, and native SOL transactions. Enables Solana ecosystem analysis, token economics research, and high-performance blockchain activity studies."
            ;;
    esac
done

echo ""
echo "========================================"
echo "TABLE COMMENTS"
echo "========================================"

# Process each network
for network in "${NETWORKS[@]}"; do
    echo ""
    echo "Processing network: ${network}"
    echo "----------------------------------------"
    
    # =============================================
    # Contracts Tables (Mainnet only)
    # =============================================
    
    if [ "$network" = "mainnet" ]; then
        echo "Processing $CONTRACTS_VERSION tables..."
        execute_alter "$network" "$CONTRACTS_VERSION" "contracts" "Comprehensive Ethereum mainnet smart contract registry with deployment data, bytecode analysis, and verification status. Foundation for protocol research, security analysis, and ecosystem mapping across all deployed contracts."
    fi
    
    # =============================================
    # Solana Tables (Solana only)
    # =============================================
    
    if [ "$network" = "solana" ]; then
        echo "Processing $SOLANA_DEX_VERSION tables..."
        
        # Core Tables
        execute_alter "$network" "$SOLANA_DEX_VERSION" "blocks" "Solana block metadata with timestamp and hash information for chronological analysis and block-based queries. Essential reference data for temporal aggregations and cross-table block correlations in DEX analysis."
        
        execute_alter "$network" "$SOLANA_DEX_VERSION" "swaps" "Unified Solana DEX swap events across all major protocols with standardized token amounts and pricing data. Primary dataset for cross-protocol trading analysis, arbitrage detection, and Solana DeFi ecosystem research."
        
        execute_alter "$network" "$SOLANA_DEX_VERSION" "ohlc_prices" "Open, High, Low, Close price data for Solana DEX trading pairs with time-series market data for technical analysis. Essential for price charting, volatility research, and trading strategy development across Solana protocols."
        
        # Jupiter DEX Aggregator Tables
        execute_alter "$network" "$SOLANA_DEX_VERSION" "jupiter_swap" "Jupiter DEX aggregator swap events with multi-route optimization and cross-AMM execution data. Critical for analyzing DEX aggregation efficiency, optimal routing strategies, and Jupiter ecosystem trading patterns."
        
        # Pump.fun Protocol Tables
        execute_alter "$network" "$SOLANA_DEX_VERSION" "pumpfun_buy" "Pump.fun token purchase events with bonding curve mechanics and fee distribution tracking. Essential for analyzing meme token launches, bonding curve trading dynamics, and pump.fun ecosystem growth."
        
        execute_alter "$network" "$SOLANA_DEX_VERSION" "pumpfun_sell" "Pump.fun token sale events with bonding curve mechanics and liquidity extraction patterns. Important for analyzing token exit strategies, bonding curve sustainability, and pump.fun trading behavior."
        
        execute_alter "$network" "$SOLANA_DEX_VERSION" "pumpfun_amm_buy" "Pump.fun AMM-based token purchases with enhanced liquidity pool interactions and fee structures. Critical for analyzing transition from bonding curve to AMM trading and liquidity migration patterns."
        
        execute_alter "$network" "$SOLANA_DEX_VERSION" "pumpfun_amm_sell" "Pump.fun AMM-based token sales with liquidity pool dynamics and advanced fee distribution mechanisms. Essential for analyzing AMM trading efficiency and pump.fun protocol evolution."
        
        # Raydium AMM V4 Protocol Tables (Enhanced)
        execute_alter "$network" "$SOLANA_DEX_VERSION" "raydium_amm_v4_swap_base_in" "Raydium AMM V4 base-token-in swap events with detailed market integration and vault interaction data. Core dataset for analyzing base token trading patterns, market coupling effects, and Raydium-OpenBook integration."
        
        execute_alter "$network" "$SOLANA_DEX_VERSION" "raydium_amm_v4_swap_base_out" "Raydium AMM V4 base-token-out swap events with comprehensive vault state and market interaction tracking. Essential for analyzing quote token trading patterns, liquidity utilization, and AMM efficiency metrics."
        
        # Materialized Views for Performance
        execute_alter "$network" "$SOLANA_DEX_VERSION" "mv_jupiter_swap" "Materialized view of Jupiter swaps with optimized indexing for high-performance DEX aggregation analysis. Pre-computed aggregations for efficient multi-protocol trading research and route optimization studies."
        
        execute_alter "$network" "$SOLANA_DEX_VERSION" "mv_pumpfun_buy" "Materialized view of Pump.fun purchases with enhanced indexing for bonding curve analysis and meme token research. Optimized for high-frequency launch tracking and trading pattern detection."
        
        execute_alter "$network" "$SOLANA_DEX_VERSION" "mv_pumpfun_sell" "Materialized view of Pump.fun sales with optimized querying for exit pattern analysis and bonding curve sustainability research. Pre-processed data for efficient token lifecycle studies."
        
        execute_alter "$network" "$SOLANA_DEX_VERSION" "mv_pumpfun_amm_buy" "Materialized view of Pump.fun AMM purchases with comprehensive indexing for liquidity transition analysis. Enhanced for AMM migration research and protocol evolution studies."
        
        execute_alter "$network" "$SOLANA_DEX_VERSION" "mv_pumpfun_amm_sell" "Materialized view of Pump.fun AMM sales with optimized performance for liquidity analysis and fee distribution research. Pre-computed metrics for efficient AMM trading behavior studies."
        
        execute_alter "$network" "$SOLANA_DEX_VERSION" "mv_raydium_amm_v4_swap_base_in" "Materialized view of Raydium base-in swaps with enhanced indexing for market integration analysis. Optimized for high-performance base token trading research and AMM-DEX coupling studies."
        
        execute_alter "$network" "$SOLANA_DEX_VERSION" "mv_raydium_amm_v4_swap_base_out" "Materialized view of Raydium base-out swaps with comprehensive performance optimization for quote token analysis. Pre-computed aggregations for efficient liquidity research and trading efficiency studies."
        
        execute_alter "$network" "$SOLANA_DEX_VERSION" "mv_ohlc_prices" "Materialized view of OHLC price data with time-series optimization for high-performance charting and technical analysis across Solana protocols. Pre-computed aggregations for fast price visualization and market research."

        echo "Processing $SOLANA_TOKENS_VERSION tables..."
        
        # Core Token Tables
        execute_alter "$network" "$SOLANA_TOKENS_VERSION" "approves" "SPL token approval events granting delegate permissions with multisig authority support on Solana. Essential for analyzing token delegation patterns, DeFi protocol integrations, and multisig governance mechanisms."
        
        execute_alter "$network" "$SOLANA_TOKENS_VERSION" "balance_changes" "Atomic SPL token balance change events with precise delta tracking for all token movements on Solana. Foundation for real-time balance calculations, high-frequency trading analysis, and token flow pattern detection."
        
        execute_alter "$network" "$SOLANA_TOKENS_VERSION" "balances" "Current SPL token balances snapshot for all token holders with owner-mint mapping on Solana. Real-time view of token holdings optimized for portfolio analysis and wealth distribution research."
        
        execute_alter "$network" "$SOLANA_TOKENS_VERSION" "balances_by_mint" "Current SPL token balances organized by mint address with holder statistics on Solana. Optimized for token-centric analysis, holder distribution studies, and mint-specific economic research."
        
        execute_alter "$network" "$SOLANA_TOKENS_VERSION" "blocks" "Solana block metadata with timestamp normalization and genesis-relative timing for chronological analysis. Essential reference data for temporal queries and block-based aggregations."
        
        execute_alter "$network" "$SOLANA_TOKENS_VERSION" "initialize_accounts" "SPL token account initialization events tracking new token account creation and ownership assignment on Solana. Critical for analyzing token adoption patterns and account lifecycle management."
        
        execute_alter "$network" "$SOLANA_TOKENS_VERSION" "initialize_mints" "SPL token mint initialization events capturing new token deployments with authority configuration on Solana. Foundation for token genesis analysis, authority tracking, and ecosystem growth studies."
        
        execute_alter "$network" "$SOLANA_TOKENS_VERSION" "revokes" "SPL token delegation revocation events removing previously granted delegate permissions on Solana. Important for analyzing security practices, permission management, and token control patterns."
        
        execute_alter "$network" "$SOLANA_TOKENS_VERSION" "transfers" "Complete SPL token transfer events with multisig authority support and comprehensive transaction context on Solana. Primary dataset for token flow analysis, trading pattern detection, and economic activity measurement."
        
        # Materialized Views for Performance
        execute_alter "$network" "$SOLANA_TOKENS_VERSION" "mv_balances" "Materialized view of current SPL token balances with optimized indexing for high-performance wallet queries on Solana. Pre-computed aggregations for fast portfolio tracking and real-time balance lookups."
        
        execute_alter "$network" "$SOLANA_TOKENS_VERSION" "mv_balances_by_mint" "Materialized view of balances organized by mint with enhanced query performance for token-centric analysis on Solana. Optimized for mint-specific holder research and token distribution studies."
    fi
    
    # =============================================
    # EVM Networks Tables
    # =============================================
    
    if [ "$network" != "solana" ]; then
        # =============================================
        # Tokens Tables
        # =============================================
        
        echo "Processing $TOKENS_VERSION_CURRENT tables..."
        
        # Core Balance Tables
        execute_alter "$network" "$TOKENS_VERSION_CURRENT" "balances" "Current account balances for all tokens and native tokens across ${network} network. Real-time snapshot of wallet holdings with efficient querying for portfolio analysis and wealth distribution research."
        
        execute_alter "$network" "$TOKENS_VERSION_CURRENT" "balances_by_contract" "Aggregated token balances organized by contract address with holder statistics on ${network}. Optimized for token distribution analysis, whale tracking, and contract-specific holder demographic research."
        
        execute_alter "$network" "$TOKENS_VERSION_CURRENT" "historical_balances" "Time-series balance data for historical portfolio reconstruction and wealth tracking on ${network}. Essential for backtesting strategies, analyzing historical whale movements, and conducting longitudinal wealth studies."
        
        execute_alter "$network" "$TOKENS_VERSION_CURRENT" "historical_balances_by_contract" "Historical aggregated balances per contract with time-series holder distribution data on ${network}. Supports analysis of token adoption curves, holder concentration trends, and ecosystem maturity metrics."
        
        # ERC20 Token Tables
        execute_alter "$network" "$TOKENS_VERSION_CURRENT" "erc20_approvals" "ERC20 token approval events tracking spending permissions granted between addresses on ${network}. Critical for analyzing DeFi protocol interactions, security research, and unlimited approval risk assessment."
        
        execute_alter "$network" "$TOKENS_VERSION_CURRENT" "erc20_balance_changes" "Atomic ERC20 balance change events with precise delta tracking for all token transfers on ${network}. Foundation for real-time balance calculations, MEV analysis, and high-frequency trading strategy development."
        
        execute_alter "$network" "$TOKENS_VERSION_CURRENT" "erc20_metadata" "Current ERC20 token metadata including names, symbols, decimals, and total supply information on ${network}. Essential reference data for token identification, display formatting, and protocol integration."
        
        execute_alter "$network" "$TOKENS_VERSION_CURRENT" "erc20_metadata_changes" "Historical ERC20 metadata modification events tracking symbol changes, supply adjustments, and other token parameter updates on ${network}. Important for detecting token migrations, rebranding events, and supply manipulation."
        
        execute_alter "$network" "$TOKENS_VERSION_CURRENT" "erc20_metadata_initialize" "Initial ERC20 token deployment metadata capturing original token parameters and deployment contexts on ${network}. Provides genesis data for token lifecycle analysis and protocol archeology research."
        
        execute_alter "$network" "$TOKENS_VERSION_CURRENT" "erc20_total_supply_changes" "ERC20 token total supply modification events including minting, burning, and inflationary mechanisms on ${network}. Essential for tokenomics analysis, inflation tracking, and monetary policy research."
        
        execute_alter "$network" "$TOKENS_VERSION_CURRENT" "erc20_transfers" "Complete ERC20 token transfer events with sender, recipient, amount, and transaction context on ${network}. The primary dataset for token flow analysis, trading pattern detection, and economic activity measurement."
        
        # Native Token Tables
        execute_alter "$network" "$TOKENS_VERSION_CURRENT" "native_balance_changes" "Native token balance change events excluding gas fees for precise balance tracking on ${network}. Essential for native token flow analysis, staking rewards calculation, and non-fee related value transfer research."
        
        execute_alter "$network" "$TOKENS_VERSION_CURRENT" "native_balance_changes_from_gas" "Native token balance changes specifically from gas fee payments and validator rewards on ${network}. Critical for analyzing network fee economics, validator revenue, and gas market dynamics research."
        
        execute_alter "$network" "$TOKENS_VERSION_CURRENT" "native_transfers" "Direct native token transfer events between addresses excluding contract interactions and gas fees on ${network}. Core dataset for analyzing peer-to-peer native token movements and non-DeFi economic activity."
        
        execute_alter "$network" "$TOKENS_VERSION_CURRENT" "native_transfers_from_fees" "Native token transfers resulting from transaction fee payments and validator rewards distribution on ${network}. Essential for understanding network economics, fee market dynamics, and validator income analysis."
        
        # Aggregated Transfer Tables
        execute_alter "$network" "$TOKENS_VERSION_CURRENT" "transfers" "Unified transfer events combining both ERC20 token and native token transfers with standardized schema on ${network}. Comprehensive dataset for cross-asset flow analysis and multi-token economic research."
        
        # Materialized Views for Performance
        execute_alter "$network" "$TOKENS_VERSION_CURRENT" "mv_balances_by_contract" "Materialized view of current balances aggregated by contract with optimized query performance on ${network}. Pre-computed aggregations for fast dashboard loading and real-time analytics applications."
        
        execute_alter "$network" "$TOKENS_VERSION_CURRENT" "mv_erc20_balances" "Materialized view of current ERC20 token balances with efficient indexing for wallet and portfolio queries on ${network}. Optimized for high-frequency balance lookups and real-time DeFi position tracking."
        
        execute_alter "$network" "$TOKENS_VERSION_CURRENT" "mv_erc20_metadata_changes" "Materialized view of ERC20 metadata changes with optimized historical lookups and change tracking on ${network}. Pre-processed data for efficient token metadata evolution analysis and debugging."
        
        execute_alter "$network" "$TOKENS_VERSION_CURRENT" "mv_erc20_metadata_initialize" "Materialized view of initial ERC20 token deployments with enhanced indexing for token discovery and genesis analysis on ${network}. Optimized for new token detection and protocol research queries."
        
        execute_alter "$network" "$TOKENS_VERSION_CURRENT" "mv_erc20_transfers" "Materialized view of ERC20 transfers with optimized indexing for high-performance trading analysis and real-time transfer monitoring on ${network}. Enhanced with computed fields for analytics performance."
        
        execute_alter "$network" "$TOKENS_VERSION_CURRENT" "mv_historical_erc20_balances" "Materialized view of historical ERC20 balances with time-series optimization for backtesting and temporal analysis on ${network}. Pre-computed snapshots for efficient historical portfolio reconstruction."
        
        execute_alter "$network" "$TOKENS_VERSION_CURRENT" "mv_historical_native_balances" "Materialized view of historical native token balances with temporal indexing for efficient time-series queries on ${network}. Optimized for native token holder analysis and historical wealth distribution studies."
        
        execute_alter "$network" "$TOKENS_VERSION_CURRENT" "mv_native_balances" "Materialized view of current native token balances with optimized querying for wallet analysis and native token distribution research on ${network}. Pre-computed aggregations for fast native token economics dashboard loading."
        
        execute_alter "$network" "$TOKENS_VERSION_CURRENT" "mv_native_transfers" "Materialized view of native token transfers with enhanced indexing for flow analysis and economic research on ${network}. Optimized for high-performance native token movement tracking and pattern detection."
        
        # =============================================
        # NFT Tables
        # =============================================
        
        echo "Processing $NFT_VERSION_CURRENT tables..."
        
        # ERC1155 Multi-Token Standard Tables
        execute_alter "$network" "$NFT_VERSION_CURRENT" "erc1155_approvals_for_all" "ERC1155 approval-for-all events granting operator permissions across entire token collections on ${network}. Essential for marketplace authorization analysis and bulk NFT operation security research."
        
        execute_alter "$network" "$NFT_VERSION_CURRENT" "erc1155_balances" "Current ERC1155 token balances tracking fungible and semi-fungible token holdings per address on ${network}. Critical for gaming asset analysis, utility token tracking, and multi-edition NFT economics."
        
        execute_alter "$network" "$NFT_VERSION_CURRENT" "erc1155_metadata_by_contract" "ERC1155 contract-level metadata including collection information, base URIs, and contract specifications on ${network}. Foundation for multi-token collection analysis and gaming ecosystem research."
        
        execute_alter "$network" "$NFT_VERSION_CURRENT" "erc1155_metadata_by_token" "Individual ERC1155 token metadata with attributes, media URLs, and token-specific properties on ${network}. Essential for gaming item analysis, utility token research, and semi-fungible asset valuation."
        
        execute_alter "$network" "$NFT_VERSION_CURRENT" "erc1155_transfers" "ERC1155 token transfer events supporting both single and batch transfers with quantity tracking on ${network}. Comprehensive dataset for gaming asset flows, utility token distribution, and multi-token economics."
        
        # ERC721 Non-Fungible Token Tables
        execute_alter "$network" "$NFT_VERSION_CURRENT" "erc721_approvals" "ERC721 individual token approval events for single NFT transfer authorization on ${network}. Critical for analyzing NFT marketplace mechanics, delegation patterns, and security research."
        
        execute_alter "$network" "$NFT_VERSION_CURRENT" "erc721_approvals_for_all" "ERC721 approval-for-all events granting operators permission over entire NFT collections on ${network}. Essential for bulk NFT operations, marketplace analysis, and security risk assessment."
        
        execute_alter "$network" "$NFT_VERSION_CURRENT" "erc721_base_uri" "ERC721 base URI configuration events tracking metadata endpoint changes and collection hosting migrations on ${network}. Important for metadata availability analysis and collection maintenance research."
        
        execute_alter "$network" "$NFT_VERSION_CURRENT" "erc721_metadata_by_contract" "ERC721 collection-level metadata including contract names, symbols, and collection specifications on ${network}. Foundation for NFT collection analysis, brand research, and ecosystem mapping."
        
        execute_alter "$network" "$NFT_VERSION_CURRENT" "erc721_metadata_by_token" "Individual ERC721 token metadata with attributes, images, and unique properties on ${network}. Core dataset for NFT valuation, rarity analysis, and cultural significance research."
        
        execute_alter "$network" "$NFT_VERSION_CURRENT" "erc721_owners" "Current ERC721 token ownership mapping with real-time holder information for all NFTs on ${network}. Essential for portfolio analysis, whale tracking, and ownership distribution research."
        
        execute_alter "$network" "$NFT_VERSION_CURRENT" "erc721_total_supply" "ERC721 collection total supply tracking with minting progress and collection size information on ${network}. Critical for scarcity analysis, mint tracking, and collection completion metrics."
        
        execute_alter "$network" "$NFT_VERSION_CURRENT" "erc721_transfers" "Complete ERC721 transfer events including mints, sales, and transfers with full transaction context on ${network}. Primary dataset for NFT market analysis, price discovery, and ownership flow research."
        
        # Generic NFT Tables
        execute_alter "$network" "$NFT_VERSION_CURRENT" "nft_metadata" "Unified NFT metadata across all token standards with normalized attributes and media information on ${network}. Comprehensive reference for cross-standard NFT analysis and ecosystem research."
        
        execute_alter "$network" "$NFT_VERSION_CURRENT" "scrape_attempts" "Metadata scraping attempt logs tracking successful and failed metadata resolution efforts on ${network}. Essential for data quality analysis, metadata availability research, and infrastructure monitoring."
        
        execute_alter "$network" "$NFT_VERSION_CURRENT" "scrape_attempts_by_contract" "Contract-level metadata scraping statistics with success rates and error patterns on ${network}. Critical for identifying problematic collections, metadata hosting issues, and collection health assessment."
        
        execute_alter "$network" "$NFT_VERSION_CURRENT" "spam_scoring" "NFT spam detection scores and classification data for filtering low-quality or malicious collections on ${network}. Essential for marketplace curation, user protection, and ecosystem health analysis."
        
        # Seaport Marketplace Protocol Tables
        execute_alter "$network" "$NFT_VERSION_CURRENT" "seaport_considerations" "Seaport protocol consideration items specifying payment terms, royalties, and additional fees in NFT marketplace orders on ${network}. Critical for analyzing marketplace economics and royalty distribution."
        
        execute_alter "$network" "$NFT_VERSION_CURRENT" "seaport_offers" "Seaport protocol offer items detailing NFTs and tokens being offered in marketplace transactions on ${network}. Essential for bid/ask analysis, liquidity research, and marketplace price discovery."
        
        execute_alter "$network" "$NFT_VERSION_CURRENT" "seaport_order_cancelled" "Seaport order cancellation events tracking withdrawn marketplace listings and failed transactions on ${network}. Important for understanding marketplace behavior, user intent, and order book dynamics."
        
        execute_alter "$network" "$NFT_VERSION_CURRENT" "seaport_order_fulfilled" "Seaport order fulfillment events representing completed NFT marketplace transactions with full execution details on ${network}. Core dataset for NFT sales analysis and marketplace volume research."
        
        execute_alter "$network" "$NFT_VERSION_CURRENT" "seaport_orders" "Complete Seaport marketplace order data including listings, offers, and complex multi-asset trades on ${network}. Comprehensive dataset for NFT marketplace analysis and trading pattern research."
        
        execute_alter "$network" "$NFT_VERSION_CURRENT" "seaport_orders_matched" "Seaport order matching events connecting buyers and sellers in marketplace transactions on ${network}. Essential for understanding marketplace efficiency, matching algorithms, and trade execution analysis."
        
        execute_alter "$network" "$NFT_VERSION_CURRENT" "seaport_orders_ohlc" "Seaport order OHLC (Open, High, Low, Close) price data for NFT collections with time-series market data on ${network}. Critical for NFT price charting, technical analysis, and market trend research."
        
        # Materialized Views for Performance
        execute_alter "$network" "$NFT_VERSION_CURRENT" "mv_erc1155_balance_from" "Materialized view of ERC1155 balances optimized for sender analysis with efficient balance tracking and historical reconstruction on ${network}. Pre-computed for high-performance gaming asset flow analysis."
        
        execute_alter "$network" "$NFT_VERSION_CURRENT" "mv_erc1155_balance_to" "Materialized view of ERC1155 balances optimized for recipient analysis with efficient balance aggregation and holder tracking on ${network}. Enhanced for multi-token portfolio analysis and holder research."
        
        execute_alter "$network" "$NFT_VERSION_CURRENT" "mv_erc721_owners" "Materialized view of current ERC721 ownership with optimized indexing for fast portfolio queries and holder analysis on ${network}. Pre-computed aggregations for real-time NFT ownership tracking."
        
        execute_alter "$network" "$NFT_VERSION_CURRENT" "mv_seaport_considerations" "Materialized view of Seaport considerations with enhanced indexing for royalty analysis and fee structure research on ${network}. Optimized for marketplace economics and creator earnings analysis."
        
        execute_alter "$network" "$NFT_VERSION_CURRENT" "mv_seaport_offers" "Materialized view of Seaport offers with optimized querying for bid analysis and liquidity research on ${network}. Pre-processed data for efficient marketplace demand analysis and price discovery."
        
        execute_alter "$network" "$NFT_VERSION_CURRENT" "mv_seaport_orders" "Materialized view of Seaport orders with comprehensive indexing for high-performance marketplace analysis on ${network}. Enhanced with computed fields for trading volume and market activity research."
        
        execute_alter "$network" "$NFT_VERSION_CURRENT" "mv_seaport_orders_ohlc" "Materialized view of Seaport OHLC data with time-series optimization for NFT price charting and technical analysis on ${network}. Pre-computed aggregations for fast market data visualization."
        
        # =============================================
        # Uniswap Tables
        # =============================================
        
        echo "Processing $UNISWAP_VERSION tables..."
        
        # Core Token Metadata Tables
        execute_alter "$network" "$UNISWAP_VERSION" "erc20_metadata" "Current ERC20 token metadata for Uniswap-traded tokens including symbols, decimals, and total supply on ${network}. Essential reference data for DEX pair analysis and token identification."
        
        execute_alter "$network" "$UNISWAP_VERSION" "erc20_metadata_changes" "Historical ERC20 metadata changes for tokens traded on Uniswap with parameter modification tracking on ${network}. Important for detecting token migrations, rebranding, and supply changes affecting trading."
        
        execute_alter "$network" "$UNISWAP_VERSION" "erc20_metadata_initialize" "Initial ERC20 token deployment metadata for Uniswap ecosystem tokens with genesis parameters on ${network}. Foundation for token lifecycle analysis and new token listing research."
        
        # Core Pool and Swap Tables
        execute_alter "$network" "$UNISWAP_VERSION" "pools" "Unified Uniswap pool registry across all protocol versions with liquidity metrics and fee tier information on ${network}. Central reference for DEX pool analysis and liquidity migration research."
        
        execute_alter "$network" "$UNISWAP_VERSION" "swaps" "Complete Uniswap swap transactions across all protocol versions with unified schema for price impact and volume analysis on ${network}. Primary dataset for DEX trading research and MEV detection."
        
        execute_alter "$network" "$UNISWAP_VERSION" "ohlc_prices" "Open, High, Low, Close price data for Uniswap trading pairs with time-series market data for technical analysis on ${network}. Essential for price charting, volatility research, and trading strategy development."
        
        execute_alter "$network" "$UNISWAP_VERSION" "pool_activity_summary" "Aggregated pool activity metrics including volume, fees, and liquidity changes with time-based summaries on ${network}. Optimized for pool performance analysis and liquidity provider research."
        
        # Uniswap V2 Protocol Tables
        execute_alter "$network" "$UNISWAP_VERSION" "uniswap_v2_burn" "Uniswap V2 liquidity removal events with LP token burning and asset withdrawal details on ${network}. Critical for analyzing liquidity provider behavior and impermanent loss calculations."
        
        execute_alter "$network" "$UNISWAP_VERSION" "uniswap_v2_mint" "Uniswap V2 liquidity provision events with LP token minting and initial deposit tracking on ${network}. Essential for analyzing liquidity addition patterns and LP token economics."
        
        execute_alter "$network" "$UNISWAP_VERSION" "uniswap_v2_pair_created" "Uniswap V2 pair creation events tracking new trading pair deployments with factory addresses on ${network}. Foundation for new pair discovery and ecosystem growth analysis."
        
        execute_alter "$network" "$UNISWAP_VERSION" "uniswap_v2_swap" "Uniswap V2 swap events with price impact, fee calculations, and routing information on ${network}. Core dataset for V2 trading analysis, arbitrage detection, and price discovery research."
        
        execute_alter "$network" "$UNISWAP_VERSION" "uniswap_v2_sync" "Uniswap V2 price synchronization events maintaining constant product invariant with reserve updates on ${network}. Important for understanding V2 mechanics and liquidity state changes."
        
        # Uniswap V3 Protocol Tables
        execute_alter "$network" "$UNISWAP_VERSION" "uniswap_v3_burn" "Uniswap V3 position burning events with concentrated liquidity removal and fee collection on ${network}. Essential for analyzing V3 liquidity strategies and position management."
        
        execute_alter "$network" "$UNISWAP_VERSION" "uniswap_v3_collect" "Uniswap V3 fee collection events from concentrated liquidity positions with earnings distribution on ${network}. Critical for LP profitability analysis and fee optimization research."
        
        execute_alter "$network" "$UNISWAP_VERSION" "uniswap_v3_collect_protocol" "Uniswap V3 protocol fee collection events with governance revenue tracking and treasury analysis on ${network}. Important for protocol economics and fee switch activation research."
        
        execute_alter "$network" "$UNISWAP_VERSION" "uniswap_v3_fee_amount_enabled" "Uniswap V3 fee tier activation events enabling new fee levels for trading pairs on ${network}. Essential for understanding fee tier adoption and pool fragmentation analysis."
        
        execute_alter "$network" "$UNISWAP_VERSION" "uniswap_v3_flash" "Uniswap V3 flash loan events with borrowing amounts and repayment tracking for arbitrage and liquidation analysis on ${network}. Critical for MEV research and flash loan utilization studies."
        
        execute_alter "$network" "$UNISWAP_VERSION" "uniswap_v3_increase_observation_cardinality_next" "Uniswap V3 oracle capacity expansion events increasing historical price data storage on ${network}. Important for oracle reliability analysis and TWAP calculation optimization."
        
        execute_alter "$network" "$UNISWAP_VERSION" "uniswap_v3_initialize" "Uniswap V3 pool initialization events setting initial price and activating trading on ${network}. Foundation for new V3 pool analysis and price discovery research."
        
        execute_alter "$network" "$UNISWAP_VERSION" "uniswap_v3_mint" "Uniswap V3 concentrated liquidity position creation with tick range and amount details on ${network}. Essential for analyzing V3 LP strategies and concentrated liquidity effectiveness."
        
        execute_alter "$network" "$UNISWAP_VERSION" "uniswap_v3_owner_changed" "Uniswap V3 factory ownership transfer events with governance transition tracking on ${network}. Important for protocol governance analysis and decentralization research."
        
        execute_alter "$network" "$UNISWAP_VERSION" "uniswap_v3_pool_created" "Uniswap V3 pool creation events with fee tier selection and initial parameters on ${network}. Critical for V3 ecosystem growth analysis and fee tier adoption research."
        
        execute_alter "$network" "$UNISWAP_VERSION" "uniswap_v3_set_fee_protocol" "Uniswap V3 protocol fee configuration events with fee switch activation and percentage settings on ${network}. Essential for protocol economics and governance decision analysis."
        
        execute_alter "$network" "$UNISWAP_VERSION" "uniswap_v3_swap" "Uniswap V3 swap events with concentrated liquidity interaction and price impact analysis on ${network}. Primary dataset for V3 trading research and capital efficiency studies."
        
        # Uniswap V4 Protocol Tables
        execute_alter "$network" "$UNISWAP_VERSION" "uniswap_v4_donate" "Uniswap V4 donation events with liquidity contributions and community incentive tracking on ${network}. Important for analyzing V4 community mechanisms and liquidity incentives."
        
        execute_alter "$network" "$UNISWAP_VERSION" "uniswap_v4_initialize" "Uniswap V4 pool initialization events with hook integration and custom pool parameters on ${network}. Foundation for V4 innovation research and hook utilization analysis."
        
        execute_alter "$network" "$UNISWAP_VERSION" "uniswap_v4_modify_liquidity" "Uniswap V4 liquidity modification events with hook execution and custom logic integration on ${network}. Essential for analyzing V4 advanced features and hook performance."
        
        execute_alter "$network" "$UNISWAP_VERSION" "uniswap_v4_protocol_fee_controller_update" "Uniswap V4 protocol fee controller configuration updates with dynamic fee management on ${network}. Critical for understanding V4 governance and adaptive fee mechanisms."
        
        execute_alter "$network" "$UNISWAP_VERSION" "uniswap_v4_protocol_fee_controller_updated" "Uniswap V4 protocol fee controller update confirmations with implementation tracking on ${network}. Important for V4 governance transition analysis and fee controller evolution."
        
        execute_alter "$network" "$UNISWAP_VERSION" "uniswap_v4_protocol_fee_updated" "Uniswap V4 protocol fee adjustment events with dynamic fee optimization and market adaptation on ${network}. Essential for analyzing V4 adaptive economics and fee optimization."
        
        execute_alter "$network" "$UNISWAP_VERSION" "uniswap_v4_swap" "Uniswap V4 swap events with hook integration, custom logic execution, and enhanced efficiency metrics on ${network}. Primary dataset for V4 innovation research and hook impact analysis."
        
        # Materialized Views for Performance
        execute_alter "$network" "$UNISWAP_VERSION" "mv_erc20_metadata_changes" "Materialized view of ERC20 metadata changes with optimized indexing for token evolution analysis on ${network}. Pre-processed data for efficient token migration and rebranding research."
        
        execute_alter "$network" "$UNISWAP_VERSION" "mv_erc20_metadata_initialize" "Materialized view of initial ERC20 deployments with enhanced indexing for new token discovery on ${network}. Optimized for token genesis analysis and Uniswap listing research."
        
        execute_alter "$network" "$UNISWAP_VERSION" "mv_ohlc_prices" "Materialized view of OHLC price data with time-series optimization for high-performance charting and technical analysis on ${network}. Pre-computed aggregations for fast price visualization."
        
        execute_alter "$network" "$UNISWAP_VERSION" "mv_pool_activity_summary" "Materialized view of pool activity metrics with comprehensive performance indexing on ${network}. Enhanced aggregations for efficient pool comparison and liquidity provider analysis."
        
        execute_alter "$network" "$UNISWAP_VERSION" "mv_uniswap_v2_pair_created" "Materialized view of V2 pair creation with optimized indexing for pair discovery and ecosystem growth analysis on ${network}. Pre-processed data for efficient V2 expansion research."
        
        execute_alter "$network" "$UNISWAP_VERSION" "mv_uniswap_v2_swap" "Materialized view of V2 swaps with enhanced indexing for high-performance trading analysis on ${network}. Optimized for V2 volume research and arbitrage opportunity detection."
        
        execute_alter "$network" "$UNISWAP_VERSION" "mv_uniswap_v3_pool_created" "Materialized view of V3 pool creation with comprehensive indexing for fee tier analysis and growth tracking on ${network}. Enhanced for V3 adoption research and pool selection studies."
        
        execute_alter "$network" "$UNISWAP_VERSION" "mv_uniswap_v3_swap" "Materialized view of V3 swaps with concentrated liquidity optimization and performance indexing on ${network}. Pre-computed metrics for efficient V3 trading analysis and capital efficiency research."
        
        execute_alter "$network" "$UNISWAP_VERSION" "mv_uniswap_v4_initialize" "Materialized view of V4 initialization events with hook integration indexing and custom parameter tracking on ${network}. Optimized for V4 innovation research and hook adoption analysis."
        
        execute_alter "$network" "$UNISWAP_VERSION" "mv_uniswap_v4_swap" "Materialized view of V4 swaps with hook execution tracking and advanced feature analysis on ${network}. Enhanced for V4 performance research and custom logic impact studies."
    fi
    
done

echo ""
echo "========================================"
echo "Multi-network database and table comments update completed!"
echo "========================================"