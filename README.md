# PAYDAY 2 - BetterLightFX
![BetterLightFX Logo](https://dl.dropboxusercontent.com/u/30675690/Payday2/BetterLightFX/logo.png)

BetterLightFX is a [Payday 2](http://store.steampowered.com/agecheck/app/218620/) mod designed to expand the default capabilities of [LightFX](http://www.alienware.com/landings/alienfx/) by including a mobile environment that is capable of indepth customization. It is easy for both the user to use the mod, as well as it is easy for developers to add their own custom effects.

# Requirements
* [Payday 2 BLT](http://paydaymods.com/download/) - A lua hook for Payday 2.
* [LightFX extender](https://github.com/Archomeda/lightfx-extender) - If you wish to experience LightFX on non-alienware hardware
* At least one piece of hardware that can run either LightFX or LightFX extender
  * [AlienFX](http://www.alienware.com/landings/alienfx/) supported device. If you have a device that is not AlienFX such as an RGB keyboard, then you can use LightFX Extender to make it work.
  * [Lightpack](http://lightpack.tv/) (used with LightFX extender)
  * Logitech devices with customizable LED lights. Tested on Logitech G910, and G19. (used with LightFX extender)
  * Corsair devices with customizable LED lights. Tested on Corsair STRAFE Red. (used with LightFX extender)
  * [Razor Chroma](http://developer.razerzone.com/chroma/compatible-devices/) devices. (used with LightFX extender)

# How to Install
1. First of all, if you do not have [Payday 2 BLT](http://paydaymods.com/download/) hook. Please download and install that.
2. Download the latest release of BetterLightFX mod from the [releases section](https://github.com/antonpup/PAYDAY-2-BetterLightFX/releases).
3. If you wish to use this mod with a Lightpack, Logitech, Corsair, or a Razer device. Please be sure to download and install [LightFX extender](https://github.com/Archomeda/lightfx-extender/releases/latest) into the Payday 2 directory.
4. Launch the game, go into Options -> Video -> Advanced -> Enable Alienware LightFX. You may have to restart the game for LightFX to take effect.
5. You can change options of BetterLightFX by going into Options -> Mod Options -> BetterLightFX Options. This includes options for any event that has options, as well as idle events.
6. If your device is not RGB, you can select a monochrome color scheme in the BetterLightFX Options.

## Included effects
* Suspicion
* Assault Indicator
* Point Of No Return
* Taken Damage
* Critical Damage
* Bleedout
* Swan Song
* Electrocution
* Flashbang
* Game Over
* Level Up
* Safe Drilled

## Video demonstration
[![BetterLightFX Demo 2](http://img.youtube.com/vi/_Kuy_CWFn08/0.jpg)](http://www.youtube.com/watch?v=_Kuy_CWFn08)

# F.A.Q.
* Q: How do I add my own custom effects with this mod?

   A: You can view the guide on the wiki page about implementing BetterLightFX into your own mod [here](https://github.com/antonpup/PAYDAY-2-BetterLightFX/wiki/How-to-implement-BetterLightFX-into-your-mod).

* Q: I have found a bug. How do I report it?

   A: You can report bugs here, by creating a new Issue [here](https://github.com/antonpup/PAYDAY-2-BetterLightFX/issues).

* Q: Does this mod have automatic updates thought BLT?

   A: Yes, automatic updates are setup.

* Q: My entire keyboard lights up one color. Can colors be split into sections?

   A: Unfortunately they cannot be split into different sections. The way Overkill implemented LightFX, changes all lights to one color.
  
* Q: Will this work with any game?

   A: This particular BLT mod will only work with Payday 2. However, [LightFX extender](https://github.com/Archomeda/lightfx-extender) will work with a variety of games that support LightFX. A full list of these games can be found here: http://alienfx.cyanlabs.net/

* Q: Can this be ported to Payday: The Heist?

   A: Maybe. ;)
   
# Credits and Mentions
* Huge shoutout to [Archomeda](https://github.com/Archomeda) for his [LightFX Extender](https://github.com/Archomeda/lightfx-extender)
* [Great Big Bushy Beard (AKA Simon)](https://github.com/GreatBigBushyBeard) for his help with developing this mod