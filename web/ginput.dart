part of geng;

DefaultButtonRender  defaultButtonRenderer = new DefaultButtonRender();

typedef void ButtonRenderer( GCanvas2D canvas, GButton btn );

class GButton extends GObj {
  
  static const int  HIDDEN = -1;
  static const int  DISABLE= 0;
  static const int  ACTIVE = 1;
  static const int  ROLLON = 3;
  static const int  PRESSED= 7;
  
  // member properties ----
  
  num x;
  num y;
  num width;
  num height;
  
  /** Z値 */
  num z = 1000;
  
  // getter properties ----
  
  num get left => x - (width/2);
  num get top  => y - (height/2);
  
  int get status {
    
    if( isVisible==false )
      return HIDDEN;
    if( isEnable==false )
      return DISABLE;
    
    if( isPress )
      return PRESSED;
    if( isOn )
      return ROLLON;
    
    return ACTIVE;
  }
  
  
  var onPress = null;
  var onRelease = null;
  
  bool  isOn = false;
  bool  isPress = false;
  bool  isVisible = true;
  bool  isEnable = true;
  
  String  text;
  
  /** ボタンレンダラ:差し替え可能 */
  ButtonRenderer renderer = defaultButtonRenderer.render;
  
  
  /** Default Constructor */
  GButton({this.text:null, this.x:320, this.y:180, this.width:100, this.height:50});
  
  
  bool isIn( num mx, num my ) {
    
    if( isVisible==false )
      return false;
    if( isEnable==false )
      return false;
    
    var xx = mx - left;
    var yy = my - top;
    bool  inH = ( xx>=0 && xx<width );
    bool  inV = ( yy>=0 && yy<height);
    
    return ( inH && inV );
  }
  
  void onInit(){}
  
  void onProcess( RenderList renderList ) {
    var s = status;
    if( s!=HIDDEN )
      renderList.add(z, (c)=>renderer(c,this) );
  }
  
  void onDispose(){}
}

class InputHandler {
  
  var onPress;
  var onRelease;
  var onMouseMove;
  var onMoveOut;
  
  void pressEvent(PressEvent e){
    if( onPress!=null )
      onPress(e);
  }
  void releaseEvent(PressEvent e){
    if( onRelease!=null )
      onRelease(e);
  }
  void mouseMoveEvent( int x, int y ) {
    if( onMouseMove!=null )
      onMouseMove(x,y);
  }
  void moveOutEvent(){
    if( onMoveOut!=null )
      onMoveOut();
  }

}


/**
 * ボタンリスト
 * ボタンっていうか入力デバイスをハンドルするオブジェクト
 */
class ButtonInputHandler extends InputHandler {
  
  /** List of Buttons */ 
  List<GButton>  _btnList = null;

  var onScreenPress;
  var onScreenRelease;
  
  void add( GButton btn ) {
    if( _btnList==null )
      _btnList = new List();
    _btnList.add( btn );
  }
  void remove( GButton btn ) {
    if( _btnList!=null )
      _btnList.remove(btn);
  }
  
  /** entryされたボタンすべてに対しPress処理をする */
  void pressEvent(PressEvent e) {
    if( _btnList!=null ) {
      _btnList.where( (b) => b.isPress==false )
        .forEach( (GButton b) {
          if( b.isIn( e.x, e.y ) ) {
            b.isPress = true;
            if( b.onPress!=null )
              b.onPress();
          }
        });
    }
  }
  
  /** entryされたボタンすべてに対しPress処理をする */
  void releaseEvent(PressEvent e) {
    if( _btnList!=null ) {
      _btnList.where( (b) => b.isPress )
        .forEach( (GButton b) {
          if( b.onRelease!=null ) {
            b.onRelease();
            b.isPress = false;
          }
        });
    }
  }
  
  /** entryされたボタンすべてに対しMove処理をする */
  void mouseMoveEvent( int x, int y ) {
    if( _btnList!=null ) {
      _btnList.where( (b) => b.isPress==false )
        .forEach( (GButton b) {
          b.isOn = b.isIn( x, y );
        });
    }
  }
  
  void moveOutEvent(){}

}
