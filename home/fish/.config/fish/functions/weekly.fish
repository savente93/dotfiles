
function weekly
    set next_wed "$(date --date='next Wednesday' -I)"
    set week_str "$(date '+%Y week %W')"
    set month_str "$(date '+%Y-%m')"
    if ! test -f ~/obsidian/stream-notes/"$next_wed".md
	obsidian create template=stream path=stream-notes/"$next_wed".md name="$next_wed"
    else
	echo "stream note already exists. skipping"
    end

    if ! test -f ~/obsidian/weekly-notes/"$week_str".md
	obsidian create template=weekly path=weekly-notes/"$week_str".md name="$week_str"
    else
	echo "weekly note already exists. skipping"
    end

    if ! test -f ~/obsidian/"kofi newsletter"/"$month_str".md
	obsidian create template=newsletter path=kofi-newsletter/"$month_str".md name="$month_str"
    else
	echo "weekly note already exists. skipping"
    end

end

