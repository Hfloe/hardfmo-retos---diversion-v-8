class_name SecurityService
extends Node

const VERIFY_URL := "https://TU-BACKEND.example.com/verify-premium"

func verify_premium_from_server() -> void:
    # Connect this function to your HTTPS backend.
    # The server must verify the Wompi transaction, Firestore users/{uid},
    # and Google Play Integrity before calling Paywall._payment_verified().
    pass

func request_play_integrity_token() -> String:
    # Expected Android plugin contract:
    # Engine.get_singleton("PlayIntegrity").request_token()
    if Engine.has_singleton("PlayIntegrity"):
        var plugin=Engine.get_singleton("PlayIntegrity")
        if plugin.has_method("request_token"):
            return str(plugin.request_token())
    return ""
