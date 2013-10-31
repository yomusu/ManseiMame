part of geng;


typedef void SpriteRender( GCanvas2D c );


class GImage {
  
  ImageElement  image;
  num offsetx = 0,
      offsety = 0;
  
  num get width => image.width;
  num get height=> image.height;
  
  GImage( String imgKey, { num offsetx:0, num offsety:0 } ) {
    image = geng.imageMap[imgKey];
    this.offsetx = offsetx;
    this.offsety = offsety;
  }
}


class ImageSprite extends Sprite {
  
  GImage  _image;
  
  set image( GImage img ) {
    _image = img;
    if( img!=null ) {
      _w = img.width;
      _h = img.height;
      offsetx = img.offsetx;
      offsety = img.offsety;
    }
  }
  
  /** 
   * img:表示する画像をImageElement形式で
   * imgkey:表示する画像をimageMapのkeyで
   */
  ImageSprite( GImage img ) : super.empty() {
    
    image = img;
    
    sprenderer = (c) {
      if( _image!=null )
        c.c.drawImageScaled(_image.image, -offsetx, -offsety, _w, _h);
    };
  }
}

/**
 * いわゆるスプライト
 */
class Sprite {
  
  num _x=0,_y=0;
  num _w=0,_h=0;
  Rectangle  _rect = null;
  
  num _alpha = null;
  num _scale = null;
  
  num offsetx = 0,
      offsety = 0;
  num rotate = null;
  
  set offset( Point p ) {
    offsetx = p.x;
    offsety = p.y;
  }
  
  bool  isShow = true;
  
  SpriteRender  sprenderer;
  
//  factory Sprite.withImage( String imgKey , { num width:null, num height:null } ) {
//    return new ImageSprite( imgKey:imgKey, width:width, height:height );
//  }
  
  Sprite.withRender( SpriteRender render, { num width:10, num height:10 } ) {
    sprenderer = render;
    _w = width;
    _h = height;
    offsetx = _w / 2;
    offsety = _h / 2;
  }
  
  Sprite.empty();
  
  void render( GCanvas2D c ) {
    if( isShow ) {
      c.c.save();
      
      if( rotate!=null ) {
        c.c.translate(_x,_y);
        c.c.rotate( rotate );
      } else {
        c.c.translate(_x,_y);
      }
      
      if( _alpha!=null ) {
        var a = _alpha;
        a = math.max( a, 0.0 );
        a = math.min( a, 1.0 );
        c.c.globalAlpha = a;
      }
      
      if( _scale!=null )
        c.c.scale( _scale, _scale );
      
      sprenderer( c );
      c.c.restore();
    }
  }
  
  /** スケール */
  num get scale => (_scale!=null) ? _scale : 1.0 ;
      set scale( num sc ) {
        _scale = (sc==1.0) ? null : sc;
      }
  
  /** 透明度 */
  num get opacity => (_alpha!=null) ? _alpha : 1.0;
      set opacity( num op ) {
        _alpha = (op==1.0) ? null : op;
      }
  
  /** 横幅 */
  num get width => _w;
      set width( num w ) {
        _w = w;
        _rect=null;
      }
  
  /** 高さ */
  num get height=> _h;
      set height( num h ) {
        _h = h;
        _rect=null;
      }
  
  
  /** x座標 */
  num get x => _x;
      set x( num n ) {
        _x = n;
        _rect=null;
      }
      
  /** y座標 */
  num get y => _y;
      set y( num n ) {
        _y = n;
        _rect=null;
      }
  
  /** get as Rect */
  Rectangle get rect {
    if( _rect==null ) {
      num x = _x - offsetx;
      num y = _y - offsety;
      _rect = new Rectangle( x,y, width, height );
    }
    return _rect;
  }
  
  void show() {
    isShow = true;
  }
  
  void hide() {
    isShow = false;
  }
}

class AnimationRender {
  
  ImageSprite dstSp;
  
  /** ここに登録してあるスプライトを順番に表示する:nullだと表示しない */
  List<GImage>  spriteList;
  int count = 0;
  int milliseconds = 0;
  var animeEndCallback;
  
  Timer _timer;
  
  /** 有限ループのアニメ。アニメ終了時にcallbackできる */
  AnimationRender.loop( int times, var callback ) {
    animeEndCallback = () {
      times--;
      if( times==0 ) {
        stop();
        callback();
      } else {
        count=0;
        fetch();
      }
    };
  }
  /** 無限ループアニメ */
  AnimationRender.mugen() {
    animeEndCallback = () {
      count=0;
      fetch();
    };
  }
  /** 1ショットだけのアニメ */
  AnimationRender.oneShot( var callback ) {
    animeEndCallback = () {
      stop();
      callback();
    };
  }
  
  GImage get current => spriteList[count];
  
  void start() {
    if( _timer!=null ) {
      _timer.cancel();
      _timer = null;
    }
    
    fetch();
    
    _timer = new Timer.periodic( new Duration(milliseconds:milliseconds), (t) {
      count++;
      
      if( count < spriteList.length ) {
        fetch();
      }
      
      if( count >= spriteList.length )
        animeEndCallback();
    });
  }
  
  void fetch() {
    dstSp.image = current;
    geng.repaint();
  }
  
  void stop() {
    if( _timer!=null ) {
      _timer.cancel();
      _timer = null;
    }
  }
  
  /** スプライトリストにスプライトを追加 */
  void add( GImage sp ) {
    if( spriteList==null )
      spriteList = new List();
    spriteList.add( sp );
  }
}

