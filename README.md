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



## List of changes



### Rel. 0.0.3


- Added bounds for ribbon when performing Saturation and Luminance.
- Scale ratio for palette window (for HDPI and non-HDPI windows).
- Highlight the default selected colour.
- Usable first implementation of the interface.


## Author

decuant


## License

The standard MIT license applies.


