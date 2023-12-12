# indexify
Bash script to create a general purpose NFT Gallery for Datalayer NFT collection on the Chia Blockchain. _Or really any NFT collection in a source folder._

check prerequisites
Parameter 1 <build_folder> must be the folder with the NFT files.  i.e.  `./build` or `./public_html`

## Example of basic folder structure for collection
```
build
   ├─ images
       ├─ 01.png
       └─ 02.png
   ├─ metadata
       ├─ 01.json
       └─ 02.json
   ├─ icon.png
   ├─ banner.png
   └─ license.md
```

* Assumption 1 - <build_folder> contains a subfolder named `images` containing all the images of the NFTs.
* Assumption 2 - <build_folder> contains a subfolder named `metadata` containing all the JSON files for the metadata of the NFTs.
* Assumption 3 - <build_folder> contains an image named `icon.png`, `icon.jpg`, or `icon.gif` containing the icon for the collection.
* Assumption 4 - <build_folder> contains an image named `banner.png`, `banner.jpg`, or `banner.gif` containing the banner for the collection.
* Assumption 5 - <build_folder> contains a file named `license.md`, `license.pdf`, or `license.txt` contain the license for the collection.

### Note 1 - The Collection data will be pulled from the first metadata file in the `metadata` folder.

Output will be a file named `index.html` in the build_folder.
