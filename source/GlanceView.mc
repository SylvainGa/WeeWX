using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.Application.Storage;
using Toybox.Application.Properties;

(:glance)
class GlanceView extends Ui.GlanceView {
    var _curPos1X;
    var _curPos2X;
    var _curPos3X;
    var _xDir1;
    var _xDir2;
    var _xDir3;
    var _refreshTimer;
    var _scrollStartTimer;
    var _scrollEndTimer;
    var _prevText1Width;
    var _prevText2Width;
    var _prevText3Width;
    var _textMaxWidth;
    var _usingFont;
    var _fontHeight;
    var _height;
    var _threeLines;

    function initialize() {
        GlanceView.initialize();
    }

	function onShow() {
        _refreshTimer = new Timer.Timer();
        _refreshTimer.start(method(:refreshView), 50, true);

        _curPos1X = null;
        _curPos2X = null;
        _curPos3X = null;
        _prevText1Width = 0;
        _prevText2Width = 0;
        _prevText3Width = 0;

        _scrollStartTimer = 0;
        _scrollEndTimer = 0;
	}

    function onLayout(dc) {
        _usingFont = (Properties.getValue("smallfontsize") ? Graphics.FONT_XTINY : Graphics.FONT_TINY);
        _fontHeight = Graphics.getFontHeight(_usingFont);
        _height = dc.getHeight();

        if (_height / _fontHeight >= 3.0) {
            _threeLines = true;
        }
        else {
            _threeLines = false;
        }

        var screenShape = System.getDeviceSettings().screenShape;
        _textMaxWidth = dc.getWidth();
        if (screenShape == System.SCREEN_SHAPE_ROUND && Properties.getValue("scrollclearsedge") == true) {
            var rad = Math.asin(_height.toFloat() * (_threeLines ? 0.8 : 1.0) / _textMaxWidth.toFloat());
            _textMaxWidth = (Math.cos(rad) * _textMaxWidth.toFloat()).toNumber();
        }

    }

	
	function onHide() {
        if (_refreshTimer) {
            _refreshTimer.stop();
            _refreshTimer = null;
        }
	}

	function refreshView() {
        Ui.requestUpdate();
	}

    function onUpdate(dc) {
        var message = Storage.getValue("message");
        var text = Storage.getValue("text");
        var textExtra;
        var title = "WeeWX";
        var _threeLines;

		//DEBUG*/ logMessage("onUpdate: message is '" + message + "'");
		//DEBUG*/ logMessage("onUpdate: text is '" + text + "'");

        if (text != null) {
            var array = to_array(text,"|");
            //DEBUG*/ logMessage("onUpdate: array size is " + array.size());
            if (array.size() > 0) {
                for (var i = 0; i < array.size(); i++) {
                    if (array[i] == null) {
                        array[i] = "";
                    }
                }
                title = array[0];
                text = array[2];
                if (_threeLines == true && array.size() > 3) {
                    textExtra = array[3];
                }
            }

            //DEBUG*/ logMessage("onUpdate: array is " + array);
        }
        else {
            text = message; // We're displaying a error
        }

        if (text == null) {
            text = "";
        }
        var text1Width = dc.getTextWidthInPixels(title, _usingFont);
        var text2Width = dc.getTextWidthInPixels(text, _usingFont);
        var text3Width = (textExtra != null ? dc.getTextWidthInPixels(textExtra, _usingFont) : 0);

        var biggestTextWidth = text1Width;
        var biggestTextWidthIndex = 1;
        if (biggestTextWidth < text2Width) {
            biggestTextWidth = text2Width;
            biggestTextWidthIndex = 2;
        }
        if (biggestTextWidth < text3Width) {
            biggestTextWidthIndex = 3;
            biggestTextWidth = text3Width;
        }

        if (_curPos1X == null || _prevText1Width != text1Width) {
            //DEBUG*/ logMessage("DC width: " + _textMaxWidth + ", text width: " + biggestTextWidth + " for line " + biggestTextWidthIndex + " DC height: " + _height + " Font height: " + _fontHeight);
            //DEBUG*/ logMessage("Showing " + title + " | " +  text + " | " + textExtra);
            _curPos1X = 0;
            _prevText1Width = text1Width;
            _scrollEndTimer = 0;
            _scrollStartTimer = 0;
            if (text1Width > _textMaxWidth) {
                _xDir1 = -4;
            }
            else {
                _xDir1 = 0;
            }
        }
        if (_curPos2X == null || _prevText2Width != text2Width) {
            _curPos2X = 0;
            _prevText2Width = text2Width;
            _scrollEndTimer = 0;
            _scrollStartTimer = 0;
            if (text2Width > _textMaxWidth) {
                _xDir2 = -4;
            }
            else {
                _xDir2 = 0;
            }
        }
        if (_curPos3X == null || _prevText3Width != text3Width) {
            _curPos3X = 0;
            _prevText3Width = text3Width;
            _scrollEndTimer = 0;
            _scrollStartTimer = 0;
            if (text3Width > _textMaxWidth) {
                _xDir3 = -4;
            }
            else {
                _xDir3 = 0;
            }
        }

        if (text1Width > _textMaxWidth || text2Width > _textMaxWidth || text3Width > _textMaxWidth) {
            if (_scrollStartTimer > 20) {
                _curPos1X = _curPos1X + _xDir1;
                _curPos2X = _curPos2X + _xDir2;
                _curPos3X = _curPos3X + _xDir3;

                if (_curPos1X + text1Width < _textMaxWidth) {
                    _xDir1 = 0;
                    if (biggestTextWidthIndex == 1) {
                        _scrollEndTimer = _scrollEndTimer + 1;              
                    }
                }
                if (_curPos2X + text2Width < _textMaxWidth) {
                    _xDir2 = 0;
                    if (biggestTextWidthIndex == 2) {
                        _scrollEndTimer = _scrollEndTimer + 1;              
                    }
                }
                if (_curPos3X + text3Width < _textMaxWidth) {
                    if (biggestTextWidthIndex == 3) {
                        _scrollEndTimer = _scrollEndTimer + 1;              
                    }
                    _xDir3 = 0;
                }
            }
            else {
                _scrollStartTimer = _scrollStartTimer + 1;
            }
        }

        // Draw the two rows of text on the glance widget
        dc.setColor(Gfx.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

        var spacing;
        if (textExtra != null && _threeLines == true) {
            spacing = ((_height - _fontHeight * 3) / 4).toNumber();

        }
        else {
            spacing = ((_height - _fontHeight * 2) / 3).toNumber();
        }

        var y = spacing;
        dc.drawText(
            _curPos1X,
            y,
            _usingFont,
            title,
            Graphics.TEXT_JUSTIFY_LEFT
        );

        y = (spacing * 2 + _fontHeight).toNumber();
        dc.drawText(
            _curPos2X,
            y,
            _usingFont,
            text,
            Graphics.TEXT_JUSTIFY_LEFT
        );

        if (textExtra != null) {
            y = (spacing * 3 + _fontHeight * 2).toNumber();
            dc.drawText(
                _curPos3X,
                y,
                _usingFont,
                textExtra,
                Graphics.TEXT_JUSTIFY_LEFT
            );
        }

        if (_scrollEndTimer == 20) {
            _curPos1X = null;
            _curPos2X = null;
            _curPos3X = null;

            _scrollEndTimer = 0;
            _scrollStartTimer = 0;
        }
    }
}
