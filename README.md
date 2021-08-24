#  **Tavolozza**


## Tavolozza - rel. 0.0.3 (2021/08/16)

An application to test colours on a sketch dialog, this simplifies the creation of colour schemes.

The application runs with ```Lua 5.4.3```, ```wxWidgets 3.1.5```, ```wxLua 3.1.0.0```.


## Modules


### .1 **main.lua**

The application uses the HSL colour space.

- Palette with primary, secondary and tertiari colours of the ```RYB``` system, plus some greys.
- 3 Pyramids wich display variations over ```Hue```, ```Saturation``` and ```Luminance```.
- Ribbon configured for ```Luminance```.

Selection of a foreground colour with the left mouse button, the background with the right mouse button.

Choosing a colour will make it current and new HSL's variations displayed.

The ribbon at the bottom can be configured to work with either each of HSL, but the preferred is Luminance.

Ribbon colours are fixed, so that the center colour is always the original one.


The controls on the main dialog.

![The actual tavolozza](/docs/Main_Dialog.png)


The sketch dialog with most used wxWidgets controls.

![The sketch dialog](/docs/Test_Dialog.png)


The stack dialog with colour armonies for the current colour selected. This is the outcome by column:

```
- 150	-- split-complementary left
- 120	-- triadic left
-  30	-- analogous left
-   0	-- original
```

![The stack dialog](/docs/Stack_Dialog.png)


The scope dialog with suitable background colours for the current foreground. The current colour is offseted by 60 degrees and made brighter or darker depending on the colour's own luminance.

![The scope dialog](/docs/Scope_Dialog.png)




## List of changes



### Rel. 0.0.3


- Added scope dialog with background colour armonies.
- Added stack dialog with foreground colour armonies.
- Added bounds for ribbon when performing Saturation and Luminance.
- Scale ratio for palette window (for HDPI and non-HDPI windows).
- Highlight the default selected colour.
- Usable first implementation of the interface.


## Author

decuant


## License

The standard MIT license applies.


