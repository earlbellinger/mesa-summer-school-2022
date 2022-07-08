for dir in $(ls); do
    if [[ -d $dir && $dir -ne "grid" ]]; then
        tar \
            --exclude="$dir/star"\
            --exclude="$dir/LOGS"\
            --exclude="$dir/photos"\
            --exclude="$dir/.mesa_temp_cache"\
            -cvzf $dir.tar.gz $dir
    fi
done
