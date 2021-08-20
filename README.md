#  **Tavolozza**


## Tavolozza - rel. 0.0.3 (2021/08/16)

An application to test colours on a sketch dialog, this simplifies the creation of colour schemes.

The application runs with ```Lua 5.4.3```, ```wxWidgets 3.1.5```, ```wxLua 3.1.0.0```.


## Modules


### .1 **main.lua**

The application uses the HSL colour space.

- ```RYB``` palette (the painters' palette).
- ```Hue``` variations.
- Decreasing ```Saturation```.
- ```Luminance``` variations.
- 18 ```Tints```.

Selection of a foreground colour with the left mouse button, the background with the right mouse button.

Choosing a colour (except in Tints) will make it current and new HSL's variations displayed.

The controls on the main dialog.

![The actual tavolozza](/doc/Main_Dialog.png)


The sketch dialog with most used wxWidgets controls.

![The sketch dialog](/doc/Test_Dialog.png)



## List of changes



### Rel. 0.0.3


- Scale ratio for palette window (for HDPI and non-HDPI windows).
- Highlight the default selected colour.
- Usable first implementation of the interface.


## Author

decuant


## License

The standard MIT license applies.


