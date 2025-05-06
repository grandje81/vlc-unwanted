# <a id="top">VLC - The Unwanted extension!</a>

- [About](#about)
- [Configuration](#configuration) 
- [Issues]("#issues")

### <a id="about">About</a>
This extensions helps with moving or removal of files that you do not want to keep in your library.
<p>
The extension is based on a rating extension developed by pragma <br>
<a href="https://github.com/pragma-/vlc-ratings">GitHub page for pragma</a>
<p>
The functions for deletion is based on extension developed by surrim <br>
<a href="https://github.com/surrim/vlc-delete">GitHub page for surrim</a>

<a href="#top">Back</a>

### <a id="configuration">Configuration</a>
The extension reads its configuration from a configuration file, it will look for this file in the same folder as the configuration for VLC. <br>
The name of the configuration file is "unwanted.cfg". <br>
Which is in the time of writing found under <b>C:\Users\%username%\AppData\Roaming\vlc\ </b> <br>
The same folder is used for the data file that is used to store the ratings and locked status of the files. <br>
The path for the folder can be overridden by setting the data_root variable in the extension file, <br>
or in the configuration file. <br>

<p>
Either way, its the element for "data_root" that needs to be set. <br>
A altered configuration file must exist in the new "data_root" directory since, not setting it will create one with default values, <br>
otherwise a configuration loop issue will occur. <br>

<p>
Settings that can be set in the configuration file are:
<ol>
	<li>max_rating - maximum rating that can be set. Default is 5.
	<li>default_rating - default rating for new files. Default is 0.
	<li>write_metadata - write rating to metadata. Default is false.
	<li>write_datafile - write data file. Default is false.
	<li>show_locked - show locked checkbox in GUI. Default is false.
	<li>show_reset_ratings - show reset ratings button in GUI. Default is false.
	<li>show_settings_default_rating - show default rating in GUI. Default is false.
	<li>delete - delete file when rating is set, except for rating of 5, its so good it has to be spared. Default is false.
	<li>move - move file when rating is set. Default is true.
	<li>data_root - path to the root folder where the data file and configuration file is stored.
	<li>data_dest_1 - path to the folder where the files with rating 1 will be moved to.
	<li>data_dest_2 - path to the folder where the files with rating 2 will be moved to.
	<li>data_dest_3 - path to the folder where the files with rating 3 will be moved to.
	<li>data_dest_4 - path to the folder where the files with rating 4 will be moved to.
	<li>data_dest_5 - path to the folder where the files with rating 5 will be moved to.
	<li>filename_removed_files - name of the file where the path to the move/delete files will be stored. Default is "removed_files.txt".
</ol>
<br>
<a href="#top">Back</a>
<br>

### <a id="issues">Reporting issues/bugs/feedback</a>

The extensions is a work in progress and is not finished yet. <br>
Lingering stale code and functions are still in the extension. <br> 
If you find any issues or want to share feedback, please feel free to do so at
<a href="https://github.com/grandje81/vlc-unwanted/issues">https://github.com/grandje81/vlc-unwanted/issues</a>!
<p>
<a href="#top">Back</a>
