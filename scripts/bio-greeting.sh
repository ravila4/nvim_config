#!/bin/bash

# Time-based bioinformatics greetings for Neovim dashboard
hour=$(date +%H)

# Define greeting arrays based on time of day
if [ "$hour" -lt 5 ]; then
    # Late night (midnight - 5am)
    greetings=(
        "🧬 Night owl sequencing mode activated"
        "🔬 Late-night data mining in progress"
        "⭐ Burning the midnight genomics oil"
        "🌙 When the lab sleeps, the code awakens"
        "🧪 Nocturnal bioinformatics adventures"
        "💫 Processing petabytes under starlight"
    )
elif [ "$hour" -lt 12 ]; then
    # Morning (5am - noon)  
    greetings=(
        "🌅 Good morning, data scientist!"
        "☕ Coffee + code = genomic discoveries"
        "🧬 Fresh morning, fresh sequences"
        "🔬 Rise and align those reads!"
        "🌱 Growing insights from raw data"
        "⚡ Energized for algorithmic adventures"
        "🧪 Morning brew meets pipeline queues"
        "🔍 Dawn of discovery awaits"
    )
elif [ "$hour" -lt 17 ]; then
    # Afternoon (noon - 5pm)
    greetings=(
        "🌞 Afternoon analysis session!"
        "📊 Peak productivity hours ahead"
        "🧬 Midday mutations and modifications"
        "💻 Crunching numbers and nucleotides"
        "🔬 Science never sleeps, but you should eat"
        "⚗️ Brewing brilliant bioinformatics"
        "🎯 Targeting those tricky datasets"
        "🚀 Launching into afternoon algorithms"
    )
elif [ "$hour" -lt 21 ]; then
    # Evening (5pm - 9pm)
    greetings=(
        "🌆 Evening exploration expedition!"
        "🧬 Sunset sequences and statistics"
        "🔬 Golden hour genomics session"
        "📈 Trending toward breakthrough insights"
        "💡 Illuminating data in twilight"
        "🎨 Painting patterns in protein structures"
        "⭐ Evening stars align like base pairs"
        "🌙 Nocturne of nucleotide analysis"
    )
else
    # Night (9pm - midnight)
    greetings=(
        "🌃 Night shift bioinformatics mode"
        "🧬 Evening evolution explorations"
        "🔬 Microscopic midnight mysteries"
        "📊 Charting constellations in data"
        "💻 Code by candlelight (or screen glow)"
        "🧪 Brewing late-night breakthroughs"
        "🌟 Stellar insights await discovery"
        "⚡ Electric evenings of exploration"
    )
fi

# Select random greeting from the appropriate time period
num_greetings=${#greetings[@]}
random_index=$((RANDOM % num_greetings))
selected_greeting="${greetings[$random_index]}"

# Center the text (dashboard width is 57 chars)
greeting_length=${#selected_greeting}
terminal_width=57
padding=$(((terminal_width - greeting_length) / 2))

# Create centered output with padding
if [ $padding -gt 0 ]; then
    printf "%*s%s\n" $padding "" "$selected_greeting"
else
    echo "$selected_greeting"
fi