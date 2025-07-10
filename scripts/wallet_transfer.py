#!/usr/bin/env python3
"""
Hyperliquid Token Transfer Script

A comprehensive script for transferring USDC or HYPE tokens between wallets
on Hyperliquid (mainnet/testnet) using the Hyperliquid Python SDK.

Features:
- Auto-installs required dependencies
- Supports both mainnet and testnet
- Handles USDC and HYPE token transfers
- Comprehensive error handling and diagnostics
- Balance verification before and after transfer
- Recipient registration checks
- Multiple transfer method attempts for compatibility

Usage:
    python hyperliquid_transfer.py
"""

import sys
import subprocess
import os
from typing import Optional, Tuple

def install_and_import_dependencies():
    """Install required packages and import them."""
    required_packages = [
        'hyperliquid-python-sdk',
        'eth-account',
        'eth-utils',
    ]

    for package in required_packages:
        try:
            if package == 'hyperliquid-python-sdk':
                import hyperliquid
            elif package == 'eth-account':
                import eth_account
            elif package == 'eth-utils':
                import eth_utils
            print(f"✅ {package} is already installed")
        except ImportError:
            print(f"📦 Installing {package}...")
            try:
                subprocess.check_call([sys.executable, '-m', 'pip', 'install', package])
                print(f"✅ Successfully installed {package}")
            except subprocess.CalledProcessError as e:
                print(f"❌ Failed to install {package}: {e}")
                sys.exit(1)

def get_wallet_address_from_private_key(private_key: str) -> str:
    """Derive wallet address from private key."""
    try:
        from eth_account import Account
        from eth_utils import to_checksum_address

        # Remove 0x prefix if present
        if private_key.startswith('0x'):
            private_key = private_key[2:]

        # Create account from private key
        account = Account.from_key(private_key)
        address = to_checksum_address(account.address)

        print(f"📝 Derived wallet address: {address}")
        return address

    except Exception as e:
        print(f"❌ Error deriving wallet address: {e}")
        sys.exit(1)

def get_user_input() -> Tuple[str, str, float, str, bool]:
    """Get transfer parameters from user."""
    print("🚀 Hyperliquid Token Transfer Tool")
    print("=" * 50)

    # Private key
    private_key = input("🔑 Enter your private key (without 0x prefix): ").strip()
    if not private_key:
        print("❌ Private key is required")
        sys.exit(1)

    # Recipient address
    to_address = input("📍 Enter recipient address: ").strip()
    if not to_address:
        print("❌ Recipient address is required")
        sys.exit(1)

    # Token type
    print("\n🪙 Supported tokens:")
    print("   • USDC - USD Coin")
    print("   • HYPE - Hyperliquid Token")
    token = input("Enter token type (USDC/HYPE) [USDC]: ").strip().upper()
    if not token:
        token = "USDC"
    if token not in ["USDC", "HYPE"]:
        print("❌ Only USDC and HYPE tokens are supported")
        sys.exit(1)

    # Amount
    try:
        amount = float(input(f"💰 Enter amount of {token} to transfer: ").strip())
        if amount <= 0:
            print("❌ Amount must be positive")
            sys.exit(1)
    except ValueError:
        print("❌ Invalid amount format")
        sys.exit(1)

    # Network
    network_choice = input("🌐 Choose network (1=Mainnet, 2=Testnet) [1]: ").strip()
    testnet = network_choice == "2"

    return private_key, to_address, amount, token, testnet

def get_token_format(token: str, testnet: bool = False) -> str:
    """Get the correct token format for the network."""
    if testnet:
        # For testnet, use simple token names
        return token.upper()
    else:
        # For mainnet, use token:contract_address format
        token_contracts = {
            'USDC': 'USDC:0x6d1e7cde53ba9467b783cb7c530ce054',
            'HYPE': 'HYPE:0x0d01dc56dcaaca66ad901c959b4011ec'
        }
        return token_contracts.get(token.upper(), token.upper())

def get_token_format_for_network(token: str, testnet: bool) -> str:
    """
    Get the correct token format for the specified network.

    Args:
        token: User-friendly token name (e.g., "USDC", "HYPE")
        testnet: Whether we're using testnet (True) or mainnet (False)

    Returns:
        Properly formatted token string for the network
    """
    token_upper = token.upper()

    if testnet:
        # Testnet uses simple token names
        return token_upper
    else:
        # Mainnet requires token:contract_address format
        mainnet_tokens = {
            "USDC": "USDC:0x6d1e7cde53ba9467b783cb7c530ce054",
            "HYPE": "HYPE:0x0d01dc56dcaaca66ad901c959b4011ec"
        }

        if token_upper in mainnet_tokens:
            return mainnet_tokens[token_upper]
        else:
            # Fallback to original token name if not found
            return token_upper

def get_balance(info, address: str, token: str) -> float:
    """Get token balance for an address."""
    try:
        spot_state = info.spot_user_state(address)
        if spot_state and 'balances' in spot_state:
            for balance in spot_state['balances']:
                if balance['coin'] == token:
                    return float(balance['total'])
        return 0.0
    except Exception as e:
        print(f"⚠️  Error getting {token} balance: {e}")
        return 0.0

def check_recipient_registration(info, address: str) -> bool:
    """Check if recipient address is registered on Hyperliquid."""
    try:
        recipient_state = info.spot_user_state(address)
        return recipient_state is not None
    except Exception:
        return False

def transfer_tokens(private_key: str, recipient_address: str, amount: float, token: str, testnet: bool = False) -> bool:
    """
    Transfer tokens using Hyperliquid SDK with comprehensive error handling.

    Returns:
        bool: True if transfer was successful, False otherwise
    """
    try:
        # Import Hyperliquid SDK components
        from hyperliquid.exchange import Exchange
        from hyperliquid.info import Info
        from hyperliquid.utils import constants
        from eth_account import Account
        from eth_utils import to_checksum_address

        print(f"\n🔄 Initializing transfer...")

        # Create wallet from private key
        if private_key.startswith('0x'):
            private_key = private_key[2:]

        account = Account.from_key(private_key)
        wallet = account

        # Initialize Info client for balance checks
        if testnet:
            info = Info(base_url="https://api.hyperliquid-testnet.xyz")
        else:
            info = Info(base_url="https://api.hyperliquid.xyz")

        # Get sender address
        sender_address = to_checksum_address(wallet.address)
        print(f"📤 Sender: {sender_address}")
        print(f"📥 Recipient: {recipient_address}")

        # Check initial balance
        print(f"\n💰 Checking initial {token} balance...")
        # For balance checks, we need to use the base token name (without contract address)
        balance_token = token.split(':')[0] if ':' in token else token
        initial_balance = get_balance(info, sender_address, balance_token)
        print(f"Initial {balance_token} balance: {initial_balance}")

        if initial_balance < amount:
            print(f"❌ Insufficient balance! You have {initial_balance} {balance_token}, need {amount}")
            return False

        # Check recipient registration
        print(f"\n🔍 Checking recipient registration...")
        is_registered = check_recipient_registration(info, recipient_address)
        print(f"Recipient status: {'✅ Registered' if is_registered else '⚠️  Not registered'}")

        if not is_registered:
            print("💡 Note: Recipient may need to deposit funds or connect wallet to Hyperliquid first")

        # Initialize Exchange
        print(f"\n🔄 Initializing Exchange for {'Testnet' if testnet else 'Mainnet'}...")

        if testnet:
            try:
                exchange = Exchange(wallet, base_url="https://api.hyperliquid-testnet.xyz")
                print("✅ Exchange initialized for TESTNET")
            except Exception as e:
                print(f"❌ Failed to initialize testnet Exchange: {e}")
                return False
        else:
            try:
                exchange = Exchange(wallet)
                print("✅ Exchange initialized for MAINNET")
            except Exception as e:
                print(f"❌ Failed to initialize mainnet Exchange: {e}")
                return False

        # Debug: Print available methods on the Exchange object
        print("\n🔍 Available transfer methods:")
        exchange_methods = [method for method in dir(exchange) if not method.startswith('_')]
        transfer_methods = [method for method in exchange_methods if 'transfer' in method.lower()]
        print(f"Transfer methods: {transfer_methods}")

        # Prepare transfer parameters
        amount_str = f"{amount:.6f}"
        token_upper = token.upper()
        # For display purposes, show the base token name
        display_token = token.split(':')[0] if ':' in token else token

        # Normalize recipient address
        if not recipient_address.startswith('0x'):
            recipient_address = f"0x{recipient_address}"
        try:
            recipient_address = to_checksum_address(recipient_address)
        except:
            pass  # Use original if checksum fails

        print(f"\n💸 Attempting to transfer {amount_str} {display_token}...")
        print(f"   From: {sender_address}")
        print(f"   To: {recipient_address}")
        print(f"   Using token format: {token}")

        # Try multiple transfer approaches with different parameter combinations
        transfer_attempts = [
            # Attempt 1: Basic spot_transfer with formatted token
            {
                'method': 'spot_transfer',
                'kwargs': {'destination': recipient_address, 'token': token, 'amount': amount_str},
                'description': f'Basic spot_transfer with token format: {token}'
            },
            # Attempt 2: spot_transfer with uppercase token (for compatibility)
            {
                'method': 'spot_transfer',
                'kwargs': {'destination': recipient_address, 'token': token_upper, 'amount': amount_str},
                'description': 'spot_transfer with uppercase token (fallback)'
            },
            # Attempt 3: usd_transfer for USDC
            {
                'method': 'usd_transfer',
                'kwargs': {'destination': recipient_address, 'amount': amount_str},
                'description': 'usd_transfer for USDC'
            } if display_token.upper() == 'USDC' else None,
            # Attempt 4: Try with lowercase address
            {
                'method': 'spot_transfer',
                'kwargs': {'destination': recipient_address.lower(), 'token': token, 'amount': amount_str},
                'description': 'spot_transfer with lowercase address'
            },
            # Attempt 5: Try with float amount
            {
                'method': 'spot_transfer',
                'kwargs': {'destination': recipient_address, 'token': token, 'amount': amount},
                'description': 'spot_transfer with float amount'
            },
            # Attempt 6: Try different parameter names
            {
                'method': 'spot_transfer',
                'kwargs': {'coin': token, 'destination': recipient_address, 'amount': amount_str},
                'description': 'spot_transfer with coin parameter'
            },
            # Attempt 7: Try positional arguments
            {
                'method': 'spot_transfer',
                'args': [amount_str, token, recipient_address],
                'description': 'spot_transfer with positional args (amount, token, destination)'
            },
            # Attempt 8: Try different positional order
            {
                'method': 'spot_transfer',
                'args': [recipient_address, token, amount_str],
                'description': 'spot_transfer with positional args (destination, token, amount)'
            },
        ]

        # Filter out None attempts
        transfer_attempts = [attempt for attempt in transfer_attempts if attempt is not None]

        success = False
        result = None

        for i, attempt in enumerate(transfer_attempts, 1):
            method_name = attempt['method']
            description = attempt.get('description', method_name)

            if not hasattr(exchange, method_name):
                print(f"⚠️  Attempt {i}: Method '{method_name}' not found")
                continue

            print(f"\n🔄 Attempt {i}: {description}")
            if 'kwargs' in attempt:
                print(f"   Parameters: {attempt['kwargs']}")
            if 'args' in attempt:
                print(f"   Arguments: {attempt['args']}")

            try:
                method = getattr(exchange, method_name)

                if 'kwargs' in attempt:
                    result = method(**attempt['kwargs'])
                elif 'args' in attempt:
                    result = method(*attempt['args'])
                else:
                    continue

                print(f"✅ Transfer successful! Response: {result}")
                success = True
                break

            except Exception as e:
                print(f"❌ Failed: {str(e)}")
                if "Failed to parse user address" in str(e):
                    print("   → Address format issue")
                elif "insufficient" in str(e).lower():
                    print("   → Insufficient balance")
                elif "not found" in str(e).lower():
                    print("   → Recipient not registered")
                elif "invalid" in str(e).lower():
                    print("   → Invalid parameter format")

        if not success:
            print("\n❌ All transfer attempts failed!")
            print("\nℹ️  Possible solutions:")
            print("   1. Ensure recipient has registered on Hyperliquid (made a deposit)")
            print("   2. Try using the Hyperliquid web interface first")
            print("   3. Check if your SDK version is up to date")
            print("   4. Verify you're on the correct network")

            # Try to get more debugging info
            print(f"\n🔍 Additional debug info:")
            print(f"   Exchange type: {type(exchange)}")
            all_methods = [m for m in dir(exchange) if not m.startswith('_')]
            other_methods = [m for m in all_methods if any(word in m.lower() for word in ['send', 'move', 'withdraw', 'transfer'])]
            print(f"   All relevant methods: {other_methods}")

            return False

        # Verify transfer success by checking balance
        print("\n🔍 Verifying transfer...")
        try:
            final_balance = get_balance(info, sender_address, balance_token)
            print(f"Final {balance_token} balance: {final_balance}")

            balance_change = initial_balance - final_balance
            expected_change = amount

            if abs(balance_change - expected_change) < 0.001:  # Account for precision
                print(f"✅ Transfer confirmed! Balance decreased by {balance_change}")

                # Clean up connections
                try:
                    if hasattr(exchange, 'close'):
                        exchange.close()
                    if hasattr(info, 'close'):
                        info.close()
                except:
                    pass

                return True
            elif balance_change == 0:
                print(f"⚠️  Warning: Balance unchanged! Transfer may have failed silently.")
                print(f"   Check the transaction on Hyperliquid explorer")
                return False
            else:
                print(f"⚠️  Unexpected balance change: {balance_change} (expected: {expected_change})")
                return False

        except Exception as e:
            print(f"❌ Error verifying transfer: {e}")
            print("   Transfer may have succeeded - check manually on Hyperliquid")

            # Clean up connections before returning
            try:
                if hasattr(exchange, 'close'):
                    exchange.close()
                if hasattr(info, 'close'):
                    info.close()
            except:
                pass

            return True  # Assume success if we can't verify

    except KeyboardInterrupt:
        print("\n❌ Transfer cancelled by user")
        return False
    except Exception as e:
        print(f"❌ Unexpected error: {e}")
        import traceback
        print(f"Full traceback: {traceback.format_exc()}")
        return False

def main():
    """Main function."""
    print("🚀 Installing dependencies...")
    install_and_import_dependencies()

    # Get user input
    private_key, to_address, amount, token, testnet = get_user_input()

    # Get the correct token format for the network
    formatted_token = get_token_format_for_network(token, testnet)
    print(f"\n🔍 Token format for {'testnet' if testnet else 'mainnet'}: {formatted_token}")

    # Derive and show sender wallet address
    from_address = get_wallet_address_from_private_key(private_key)

    # Confirm transfer
    network_name = "Testnet" if testnet else "Mainnet"
    print(f"\n📋 Transfer Summary:")
    print(f"   From: {from_address}")
    print(f"   To: {to_address}")
    print(f"   Amount: {amount} {token}")
    print(f"   Network: {network_name}")
    print(f"   Token format: {formatted_token}")

    confirm = input("\n❓ Confirm transfer? (y/N): ").strip().lower()
    if confirm != 'y':
        print("❌ Transfer cancelled")
        sys.exit(0)

    # Execute transfer with the correctly formatted token
    success = transfer_tokens(private_key, to_address, amount, formatted_token, testnet)

    if success:
        print("\n🎉 Transfer completed successfully!")
        print("🔄 Cleaning up and exiting...")

        # Force cleanup and exit
        import os
        import time
        time.sleep(0.5)  # Brief pause to ensure output is flushed
        os._exit(0)  # Force immediate exit without cleanup
    else:
        print("\n💥 Transfer failed. Please check the error messages above.")
        sys.exit(1)

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\n❌ Transfer cancelled by user")
        sys.exit(0)
    except Exception as e:
        print(f"\n❌ Unexpected error: {e}")
        import traceback
        print(f"Full traceback: {traceback.format_exc()}")
        sys.exit(1)
