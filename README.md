# VLC - The Unwanted extension!

- [About](#about)
- [Configuration](#configuration)
- [Issues](#issues)

## About

This extensions helps with moving or removal of files that you do not want to keep in your library.

The extension is based on a rating extension developed by pragma
[GitHub page for pragma](https://github.com/pragma-/vlc-ratings)

The functions for deletion is based on extension developed by surrim
[GitHub page for surrim](https://github.com/surrim/vlc-delete)

[Back to top](#vlc---the-unwanted-extension)

### Configuration

The extension reads its configuration from a configuration file, it will look for this file in the same folder as the configuration for VLC.

The name of the configuration file is "unwanted.cfg".
Which is in the time of writing found under **C:\Users\\%username%\AppData\Roaming\vlc**
The same folder is used for the data file that is used to store the ratings and locked status of the files.
The path for the folder can be overridden by setting the data_root variable in the extension file,
or in the configuration file.

Either way, its the element for "data_root" that needs to be set.
A altered configuration file must exist in the new "data_root" directory since, not setting it will create one with default values,
otherwise a configuration loop issue will occur.

Settings that can be set in the configuration file are:

1. `max_rating` - maximum rating that can be set. Default is 5.
2. `default_rating` - default rating for new files. Default is 0.
3. `write_metadata` - write rating to metadata. Default is false.
4. `write_datafile` - write data file. Default is false.`
5. `show_locked` - show locked checkbox in GUI. Default is false.
6. `show_reset_ratings` - show reset ratings button in GUI. Default is false.
7. `show_settings_default_rating` - show default rating in GUI. Default is false.
8. `delete` - delete file when rating is set, except for rating of 5, its so good it has to be spared. Default is false.
9. `move` - move file when rating is set. Default is true.
10. `data_root` - path to the root folder where the data file and configuration file is stored.
11. `data_dest_1` - path to the folder where the files with rating 1 will be moved to.
12. `data_dest_2` - path to the folder where the files with rating 2 will be moved to.
13. `data_dest_3` - path to the folder where the files with rating 3 will be moved to.
14. `data_dest_4` - path to the folder where the files with rating 4 will be moved to.
15. `data_dest_5` - path to the folder where the files with rating 5 will be moved to.
16. `filename_removed_files` - name of the file where the path to the move/delete files will be stored. Default is "removed_files.txt".

All the settings can be set in the configuration file, using a xml format.
i.e <max_rating>5</max_rating> will set the maximum rating to 5.

[Back to top](#vlc---the-unwanted-extension)

### Issues

Reporting issues/bugs/feedback
The extensions is a work in progress and is not finished yet.
Lingering stale code and functions are still in the extension.
If you find any issues or want to share feedback, please feel free to do so at
[https://github.com/grandje81/vlc-unwanted/issues](https://github.com/grandje81/vlc-unwanted/issues)

[Back to top](#vlc---the-unwanted-extension)
