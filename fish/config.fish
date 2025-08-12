oh-my-posh init fish --config $HOME/.poshthemes/zach-custom-test.omp.json | source 

#This function will make it where there is no fish greeting
#function fish_greeting; end

#This is a custom fish greeting with information
function fish_greeting
    set_color -o cyan
	echo " ____ ____ ____ ____ ____ ____" 
	echo "||G |||l |||e |||a |||h |||m ||"
	echo "||__|||__|||__|||__|||__|||__||"
	echo "|/__\|/__\|/__\|/__\|/__\|/__\|"
    set_color normal
end

#Default function, the below function was here by default
if status is-interactive
    # Commands to run in interactive sessions can go here
end

#The two functions below make sure the styling and colors are redrawn after actions so that the theme looks cohesive
function fish_prompt_redraw --on-event fish_focus
    commandline -f repaint
end

function fish_prompt_redraw --on-event fish_resize
    commandline -f repaint
end

