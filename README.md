# Safari Bookmarks Management Swift App

The Bookmarks Management Swift app is a command-line tool that checks the bookmarks in the Safari browser on a macOS system for broken links. The app reads the bookmarks from the Safari bookmarks plist file, and iterates through the bookmarks to check each bookmark's URL. If a bookmark's URL is broken or leads to an error, the app writes the bookmark's title, URL, and the error message to a file called "brokenLinks.txt".

## Installation

To install the app, simply clone the repository to your local machine.

__Note: if you get at runtime Error: Failed to read bookmarks plist, make sure that Bookmarks Management app has "Full Disck Access" (in System Settings)__

## Usage

Once the app is installed, you can run it from the command line.

## Contributing

If you would like to contribute to the project, feel free to fork the repository and submit a pull request. Any contributions are welcome!

## License

This project is licensed under the MIT License. See the LICENSE file for details.
