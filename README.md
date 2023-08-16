<!-- Improved compatibility of back to top link: See: https://github.com/othneildrew/Best-README-Template/pull/73 -->
<a name="readme-top"></a>
<!--
*** Thanks for checking out the Best-README-Template. If you have a suggestion
*** that would make this better, please fork the repo and create a pull request
*** or simply open an issue with the tag "enhancement".
*** Don't forget to give the project a star!
*** Thanks again! Now go create something AMAZING! :D
-->



<!-- PROJECT SHIELDS -->
<!--
*** I'm using markdown "reference style" links for readability.
*** Reference links are enclosed in brackets [ ] instead of parentheses ( ).
*** See the bottom of this document for the declaration of the reference variables
*** for contributors-url, forks-url, etc. This is an optional, concise syntax you may use.
*** https://www.markdownguide.org/basic-syntax/#reference-style-links
-->
[![Contributors][contributors-shield]][contributors-url]
[![Forks][forks-shield]][forks-url]
[![Stargazers][stars-shield]][stars-url]
[![Issues][issues-shield]][issues-url]
[![MIT License][license-shield]][license-url]
[![LinkedIn][linkedin-shield]][linkedin-url]



<!-- PROJECT LOGO -->
<br />
<div align="center">
  <a href="https://github.com/yusing/torrenium">
    <img src="assets/app_icon.png" alt="Logo" width="80" height="80">
  </a>

<h3 align="center">Torrenium</h3>

  <p align="center">
    Torrent Resource tools
    <!-- <br />
    <a href="https://github.com/yusing/torrenium"><strong>Explore the docs »</strong></a>
    <br />
    <br />
    <a href="https://github.com/yusing/torrenium">View Demo</a>
    ·
    <a href="https://github.com/yusing/torrenium/issues">Report Bug</a>
    ·
    <a href="https://github.com/yusing/torrenium/issues">Request Feature</a> -->
  </p>
</div>



<!-- TABLE OF CONTENTS -->
<details>
  <summary>Table of Contents</summary>
  <ol>
    <li>
      <a href="#about-the-project">About The Project</a>
      <ul>
        <li><a href="#built-with">Built With</a></li>
        <li><a href="#features">Features</a></li>
      </ul>
    </li>
    <li>
      <a href="#getting-started">Getting Started</a>
      <ul>
        <li><a href="#platforms">Platforms</a></li>
        <li><a href="#prerequisites">Prerequisites</a></li>
        <li><a href="#installation">Installation</a></li>
      </ul>
    </li>
    <li><a href="#usage">Usage</a></li>
    <li><a href="#roadmap">Roadmap</a></li>
    <li><a href="#contributing">Contributing</a></li>
    <li><a href="#license">License</a></li>
    <!-- <li><a href="#contact">Contact</a></li>
    <li><a href="#acknowledgments">Acknowledgments</a></li> -->
  </ol>
</details>



<!-- ABOUT THE PROJECT -->
## About The Project

<!-- [![Product Name Screen Shot][product-screenshot]](https://example.com) -->

Torrenium is an app that fetch resources from different rss providers.


### Built With

[![Flutter][Flutter]][Flutter-url]
[![Go][GoLang]][Go-url]

<p align="right">(<a href="#readme-top">back to top</a>)</p>

### Features
- Get latest content or search from different rss providers
- Download torrent/magnet from rss providers
- Subscribe to keywords, authors and categories and automatically download new content (updated hourly or manually)
- Video playback on Android/iOS
- Watch history and resume last watched position on Android/iOS
- Automatically pause download on cellular network, and resume on WiFi/ethernet

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- GETTING STARTED -->
## Getting Started

This is an example of how you may give instructions on how to build it manually.
To get a local copy up and running follow these simple example steps.

### Platforms

- iOS 11.0+
- Android 6.0+
- Windows
- Linux (WIP)
- MacOS (WIP)

### Prerequisites

- Clone the repo `git clone https://github.com/yusing/torrenium --recursive`
- Install [Flutter][Flutter-url] if not already
- Install [Go][Go-url] if not already
- *(Android build only)* Install [Android Studio](https://developer.android.com/studio) if not 
- *(iOS and MacOS build only)* Install [XCode](https://developer.apple.com/xcode/) if not already
- *(Windows build only)* Install [Visual Studio](https://visualstudio.microsoft.com/) if not already
- change directory to `go_torrent` and run the build script for your platform
    - `cd go_torrent`
    - `./build_ios.sh` for iOS
    - `build_windows.bat` for Windows
    - `build_android.bat` for Android (Build on Windows)
- Build the app
    - `flutter build [windows|apk|ios|macos|linux] --release` for Windows


### Installation

Download the release from [here][Release-url]



<!-- USAGE EXAMPLES -->
## Usage

Simply install the app and start using it.
<!-- Use this space to show useful examples of how a project can be used. Additional screenshots, code examples and demos work well in this space. You may also link to more resources. -->

<!-- _For more examples, please refer to the [Documentation](https://example.com)_ -->

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- ROADMAP -->
## Roadmap
- [*] Things listed in [Features](#features)
- [*] Windows and Android build
- [ ] iOS build *(WIP)*
- [ ] Linux and MacOS build
- [ ] Custom RSS Provider Support
- [ ] Group results by titles
- [ ] Play next episode when video ends (if available)
- [ ] Manual add torrent/magnet to torrent client by link
- [ ] Ability to decompress downloaded files (i.e. *.zip, *.rar, *.7z, etc.)
- [ ] Manga reader (for contents that extracts into images, or epub, etc.)
- [ ] Music player (for contents that extracts into audio files)
- [ ] Background services
    - [ ] Subscription / Download
    - [ ] Picture in Picture (PiP) support
    - [ ] Download status in Notification
    - [ ] Media controls in notification

See the [open issues](https://github.com/yusing/torrenium/issues) for a full list of proposed features (and known issues).

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- CONTRIBUTING -->
## Contributing

Contributions are what make the open source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

If you have a suggestion that would make this better, please fork the repo and create a pull request. You can also simply open an issue with the tag "enhancement".
Don't forget to give the project a star! Thanks again!

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- LICENSE -->
## License

Distributed under the Apache License Version 2.0. See `LICENSE.txt` for more information.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- MARKDOWN LINKS & IMAGES -->
<!-- https://www.markdownguide.org/basic-syntax/#reference-style-links -->
[contributors-shield]: https://img.shields.io/github/contributors/yusing/torrenium.svg?style=for-the-badge
[contributors-url]: https://github.com/yusing/torrenium/graphs/contributors
[forks-shield]: https://img.shields.io/github/forks/yusing/torrenium.svg?style=for-the-badge
[forks-url]: https://github.com/yusing/torrenium/network/members
[stars-shield]: https://img.shields.io/github/stars/yusing/torrenium.svg?style=for-the-badge
[stars-url]: https://github.com/yusing/torrenium/stargazers
[issues-shield]: https://img.shields.io/github/issues/yusing/torrenium.svg?style=for-the-badge
[issues-url]: https://github.com/yusing/torrenium/issues
[license-shield]: https://img.shields.io/github/license/yusing/torrenium.svg?style=for-the-badge
[license-url]: https://github.com/yusing/torrenium/blob/master/LICENSE.txt
[Flutter-url]: https://flutter.dev/
[Flutter]: https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white
[Go-url]: https://golang.org/
[GoLang]: https://img.shields.io/badge/Go-00ADD8?style=for-the-badge&logo=go&logoColor=white
[Release-url]: https://github.com/yusing/torrenium/releases