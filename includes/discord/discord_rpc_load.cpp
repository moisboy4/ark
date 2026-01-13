#include "discord_rpc.h"
#include "../../menu/config/config.hpp"
#include "../../hooks/hooks.hpp"
#include "../../sdk/sdk.hpp"
#include "../../features/events/events.hpp"

void c_discord::initialize() {
    DiscordEventHandlers Handle;
    memset(&Handle, 0, sizeof(Handle));

    Discord_Initialize("1418951638756098050", &Handle, 1, NULL);
}

void c_discord::update() {
    static bool init = false;
    if (c::misc::discord_rpc) {
    if (!init){
        initialize();
    init = true;
}    
    DiscordRichPresence discordPresence;
    memset(&discordPresence, 0, sizeof(discordPresence));
    static auto elapsed = std::time ( nullptr );

    std::string current_status = "arkane";
    if (interfaces::engine->is_connected()) {
        // show hostname and rounds remaining in the match
        std::string level = interfaces::engine->get_level_name();
        std::string rounds_info;

        int rounds_left = -1;
        if (auto mp_max = interfaces::console->get_convar("mp_maxrounds")) {
            rounds_left = mp_max->get_int() - g_rounds_played;
            if (rounds_left < 0) rounds_left = 0;
        }

        if (rounds_left >= 0)
            rounds_info = " | rounds left: " + std::to_string(rounds_left);

        if (!level.empty())
            current_status = std::string("playing on: ") + level + rounds_info;
        else
            current_status += rounds_info;
    }

    discordPresence.largeImageText = "arkane";
    discordPresence.state = current_status.c_str();
    //https://github.com/remelt/ARKANE-fix/blob/main/includes/discord/discord_rpc_image.png?raw=true
    discordPresence.largeImageKey = "https://images2.imgbox.com/57/b1/7hsWTykc_o.png";
    discordPresence.startTimestamp = elapsed;
    Discord_UpdatePresence(&discordPresence);
    } else {
        shutdown();
        init = false;
    }
}

void c_discord::shutdown() {
    Discord_ClearPresence();
    Discord_Shutdown();
}

