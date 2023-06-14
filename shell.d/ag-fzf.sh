# ag-fzf.sh
#
# Configuration for searching.

# As long as we have 'ag', use our ~/.ignore file.
if type ag &> /dev/null; then
    export FZF_DEFAULT_COMMAND='ag --path-to-ignore ~/.ignore -g ""'
fi
