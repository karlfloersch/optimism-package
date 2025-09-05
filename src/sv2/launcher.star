"""SV2 launcher for op-supervisor-v2."""

_util = import_module("/src/util.star")
_net = import_module("/src/util/net.star")


def launch(
    plan,
    sv2_params,
    chains,
    jwt_file,
    deployment_output,
    l1_config_env_vars,
    l1_rpc_url,
    log_level,
    persistent,
    tolerations,
    node_selectors,
    observability_helper,
):
    """Launch SV2 service that manages multiple chains.
    
    Args:
        plan: Kurtosis plan
        sv2_params: SV2 configuration parameters
        chains: List of chain configurations that SV2 should manage
        jwt_file: JWT file artifact
        deployment_output: Deployment artifacts
        l1_config_env_vars: L1 configuration environment variables
        l1_rpc_url: L1 RPC URL
        log_level: Log level
        persistent: Whether to use persistent storage
        tolerations: Kubernetes tolerations
        node_selectors: Kubernetes node selectors
        observability_helper: Observability configuration
        
    Returns:
        SV2 service context
    """
    plan.print("SV2 launcher called - temporarily disabled for debugging")
    # Temporarily return None to test basic integration
    return None


def _generate_sv2_config(plan, sv2_params, chains, l1_rpc_url):
    """Generate SV2 configuration JSON."""
    
    # Find chain configurations for the chains SV2 should manage
    sv2_chains = []
    for chain_config in chains:
        network_id = chain_config.network_params.network_id
        if network_id in sv2_params.chains:
            # Build chain config for SV2
            chain_cfg = {
                "l1_rpc": l1_rpc_url,
                "beacon_addr": "http://cl-1-lighthouse-geth:4000",  # Default beacon endpoint
                "l2_authrpc": "http://op-geth-{}-0:8551".format(network_id),
                "l2_userrpc": "http://op-geth-{}-0:8545".format(network_id),
                "jwt_secret": "/data/jwt.txt",  # Single JWT file for all chains
                "rollup_config": "/tmp/rollup-{}.json".format(network_id),  # Will be generated from env
                "user_rpc_listen_addr": "0.0.0.0",
                "user_rpc_port": 0,  # Use path-based routing by default
                "disable_p2p": True,
            }
            sv2_chains.append(chain_cfg)
    
    # Build complete SV2 config
    config = {
        "http_addr": "0.0.0.0",
        "http_port": 51722,
        "proxy_opnode": True,
        "sv2_data_dir": "/data",
        "confirm_depth": 0,
        "poll_interval": "200ms",
        "disable_p2p": True,
        "bind_all": True,
        "chains": sv2_chains,
    }
    
    return config


def get_sv2_managed_chains(sv2_params):
    """Get list of chain IDs managed by SV2."""
    if not sv2_params or not sv2_params.enabled:
        return []
    return sv2_params.chains


def get_sv2_rollup_rpc_url(sv2_context, chain_id):
    """Get the rollup RPC URL for a chain managed by SV2."""
    if not sv2_context or chain_id not in sv2_context.chains:
        return None
        
    # Return path-based URL for the chain
    return "http://sv2-service:{}/opnode/{}/".format(
        sv2_context.http_port, 
        chain_id
    )
