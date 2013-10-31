library geng;

import 'dart:html';
import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;
import 'dart:convert';

import 'sound.dart';

part 'sprite.dart';
part 'canvasutil.dart';
part 'gengutil.dart';
part 'ginput.dart';


final String  fontFamily = '"ヒラギノ角ゴ Pro W3", "Hiragino Kaku Gothic Pro", Meiryo, "メイリオ", "ＭＳ Ｐゴシック", Verdana, Geneva, Arial, Helvetica';

/**
 * Process処理に渡されるハンドルオブジェクト
 */
class GPInfo {
  
  int _numRepaint = 0;
  
  bool get isNeedRepaint => _numRepaint > 0;
  
  void repaint() {
    _numRepaint++;
  }
}

/**
 * 物体ひとつ
 * 定義は…
 */
abstract class GObj {
  
  /** 廃棄済みフラグ */
  bool  _isDisposed = false;
  
  /** Disposeされたかどうか */
  bool get isDisposed => _isDisposed;
  
  /** 識別するためのタグ */
  String tag;
  
  // オーバーライドすべきメソッド ---
  
  /** 最初に呼ばれる */
  void onInit();
  
  /** Process処理 */
  void onProcess( GPInfo handle );
  
  /** Renderの登録 */
  void onPrepareRender( RenderList renderList );
  
  /** 最後に呼ばれる */
  void onDispose();
  
  // 操作するためのメソッド ---
  
  void process( GPInfo handle ) => onProcess( handle );
  
  void prepareRender( RenderList renderList ) => onPrepareRender( renderList );
  
  /** 廃棄する */
  void dispose() {
    onDispose();
    // 次回のrenderで削除
    _isDisposed = true;
  }
}


/**
 * 画面の基本クラス
 */
abstract class GScreen {
  
  /** レンダリングリスト */
  final RenderList  _renderList = new RenderList();

  // メンバ変数 ---
  
  /** List of Buttons */ 
  InputHandler  input = new InputHandler();
  
  /** 毎フレームの処理 */
  var onProcess = null;
  /** 最背面描画 */
  var onBackRender = (canvas) {
    canvas.c.setFillColorRgb(255, 255, 255, 1.0);
    canvas.c.fillRect(0,0, geng.rect.width, geng.rect.height);
  };
  /** 最前面描画 */
  var onFrontRender = null;
  
  
  // オーバーライドすべきメソッド ---

  /** スタート処理:You can override this method. */
  void onStart();
  
  
  // オーバーライドしなくてよいメソッド ---
  
  /** フレームのTimerハンドル */
  void onTimer() {
    
    // 毎フレームの処理
    if( onProcess!=null )
      onProcess();
    
    // Do Processing every object
    var handle = new GPInfo();
    geng.objlist.processAll(handle);
    
    // 必要があればrender
    if( geng.popRepaintRequest() ) {
      
      geng.objlist.prepareRenderAll(_renderList);
      g2d.canvas = geng.backcanvas;
      
      // 最背面の描画
      if( onBackRender!=null ) {
        onBackRender( g2d );
      } else {
        g2d.c.setFillColorRgb(255, 255, 255, 1.0);
        g2d.c.fillRect(0,0, geng.rect.width, geng.rect.height);
      }
      
      // Do Rendering
      _renderList.renderAll( g2d );

//    print( geng.rect );
      // 終わったら削除
      _renderList.clear();
      geng.objlist.gcObj();
      
      // 最前面の描画
      if( onFrontRender!=null ) {
        onFrontRender( g2d );
      }
      
      g2d.canvas = null;
      
      // ダブルバッファのフリップ
      geng.flipBuffer();
    }
  }
}


/**
 * フィールドのPressイベント
 */
class PressEvent {
  int x,y;
}

/** 最終的にレンダリングするFunction */
typedef void Render( GCanvas2D canvas );

/**
 * レンダリングのオーダリングリスト
 */
class RenderList {
  
  final SplayTreeMap<num,Render>  _list;
  
  RenderList() :
    _list = new SplayTreeMap( (k1,k2) {
      var r = k1.compareTo(k2);
      return ( r==0 ) ? 1 : r;
    });
  
  void clear() {
    _list.clear();
  }
  void add( num z, Render r ) {
    _list[z] = r;
  }
  
  void renderAll( GCanvas2D canvas ) {
    _list.values.forEach( (r)=> r(canvas) );
  }
}

/****
 * 
 * Imageを読み込み、格納する
 * 
 */
class ImageMap {
  
  final Map<String,ImageElement>  map = new Map();
  
  void put( String key, String src ) {
    var img = new ImageElement()
    ..src = src;
    
    map[key] = img;
    
    // onLoadは効くのか？読み込み完了を待つ必要があるかどうか
    img.onLoad.listen( (v)=>print("loaded image : $key") ); 
  }
  
  void addAll( Map map ) {
    map.forEach( (k,v) => put( k, v ) );
  }
  
  ImageElement operator [](Object key) => map[key];
  
  void operator []=(String k, ImageElement v) {
    map[k] = v;
  }
  
}

class GObjList {
  
  /** 追加オブジェクトのバッファ */
  final List<GObj>  _addObjlist = new List();
  
  /** オブジェクトのリスト */
  final List<GObj>  objlist = new List();
  
  
  /**
   * DisposeされたGObjを廃棄する
   */
  void gcObj() {
    objlist.removeWhere( (v) => v.isDisposed );
  }
  
  /**
   * Objの追加
   */
  void add( GObj obj ) {
    _addObjlist.add(obj);
    obj.onInit();
  }
  
  /**
   * Objを全て破棄する
   */
  void disposeAll() {
    gcObj();
    objlist.forEach( (o)=>o.dispose() );
    gcObj();
    objlist.clear();
  }
  
  /**
   * 全てのオブジェクトをProcessしてrenderする
   */
  void processAll( GPInfo handle ) {
    
    // 追加オブジェクトリストを本物のリストに追加
    objlist.addAll( _addObjlist );
    _addObjlist.clear();
    
    // Do Processing every object
    where().forEach( (GObj v)=> v.process(handle) );
  }
  
  /**
   * 全てのオブジェクトをProcessしてrenderする
   */
  void prepareRenderAll( RenderList renderList ) {
    where().forEach( (GObj v)=> v.prepareRender(renderList) );
  }
  
  Iterable<GObj> where( [bool test(GObj obj)] ) {
    var r = objlist.where( (e) => e.isDisposed==false );
    if( test!=null )
      return r.where( (e)=>test(e) );
    return r;
  }
  
  /**
   * 指定したタグを持つGObjを探す
   * 最初に見つかったひとつ
   */
  GObj query( String tag ) {
    for( var o in objlist ) {
      if( o.tag == tag )
        return o;
    }
    return null;
  }
}


/**************
 * 
 * Game Engine
 * 
 */
class GEng {
  
  // Private Member --------
  
  GScreen _screen = null;
  Rectangle  _rect;
  
  // Property --------
  
  GObjList  objlist = new GObjList();
  
  // フィールド管理は別クラスにすべきかも
  CanvasElement  canvas = null;
  CanvasElement  backcanvas = null;
  
  final ImageMap  imageMap = new ImageMap();
  final SoundManager soundManager = new SoundManager();
  final HiScoreManager  hiscoreManager = new HiScoreManager();
  
  // setter/getter --------
  
  /** 使用するScreenのセット */
  set screen( GScreen s ) {
    Timer.run( () {
      _screen = s;
      if( s!=null ) {
        s.onStart();
        geng.repaint();
      }
    });
  }
  
  /** フィールドの大きさ */
  Rectangle get rect => _rect;
  
  num _scale = 1.0;
  
  /**
   * フィールドを初期化する
   */
  void initField( { int width, int height, num scale:1 }) {
    
    _scale = scale;
    _rect = new Rectangle(0,0,width,height);
    
    var w = (width * _scale).toInt();
    var h = (height * _scale).toInt();
    
    // for Retina対応(Retina以外でも高精細になる)
    canvas = new CanvasElement( width:w*2, height:h*2 );
    canvas.style
      ..width = "${w}px"
      ..height= "${h}px";
    canvas.context2D.scale(2*_scale, 2*_scale);
        
    backcanvas = canvas;
    
    
    // MouseDownからPressイベントを転送
    canvas.onMouseDown.listen( (MouseEvent e) {
      if( _screen!=null && _screen.input!=null ) {
        e.preventDefault();
        _screen.input.pressEvent( createPressEvent(e) );
//        print( "e.client.x=${e.client.x} offsetLeft=${geng.canvas.offsetLeft}");
      }
    });
    canvas.onMouseUp.listen( (MouseEvent e) {
      if( _screen!=null && _screen.input!=null) {
        e.preventDefault();
        _screen.input.releaseEvent( createPressEvent(e) );
      }
    });
    canvas.onMouseMove.listen( (MouseEvent e) {
      if( _screen!=null && _screen.input!=null) {
        var x = (e.client.x - geng.canvas.offsetLeft) ~/ _scale;
        var y = (e.client.y - geng.canvas.offsetTop) ~/ _scale;
        _screen.input.mouseMoveEvent( x, y );
      }
    });
    canvas.onMouseOut.listen( (MouseEvent e) {
      if( _screen!=null && _screen.input!=null)
        _screen.input.moveOutEvent();
    });
    // タッチイベント for スマホ
    PressEvent  backupForTouch = null;
    canvas.onTouchStart.listen( (TouchEvent e) {
      if( _screen!=null && _screen.input!=null) {
        e.preventDefault();
        var event = createPressEvent(e);
        _screen.input.pressEvent(event);
        backupForTouch = event;
      }
    });
    canvas.onTouchMove.listen( (TouchEvent e) {
      if( _screen!=null && _screen.input!=null) {
        var event = createPressEvent(e);
        _screen.input.moveOutEvent();
        backupForTouch = event;
      }
    });
    canvas.onTouchEnd.listen( (TouchEvent e) {
      if( _screen!=null && _screen.input!=null) {
        e.preventDefault();
        _screen.input.releaseEvent(backupForTouch);
      }
    });
    
    geng.canvas = canvas;
  }
  
  PressEvent createPressEvent( UIEvent e ) {
    PressEvent  p = new PressEvent();
    
    if( e is TouchEvent ) {
      print( (e as TouchEvent).touches.length );
      var t = (e as TouchEvent).touches[0];
      p.x = (t.client.x - geng.canvas.offsetLeft) ~/ geng._scale;
      p.y = (t.client.y - geng.canvas.offsetTop) ~/ geng._scale;
    } else if( e is MouseEvent ) {
      var m = e as MouseEvent;
      p.x = (m.client.x - geng.canvas.offsetLeft) ~/ geng._scale;
      p.y = (m.client.y - geng.canvas.offsetTop) ~/ geng._scale;
    }
    return p;
  }
  void flipBuffer() {
//    if( isRetina()==false )
//      canvas.context2D.drawImage( backcanvas, 0, 0 );
  }
  
  FrameTimer frameWatch = new FrameTimer();
  var cpucnt = new FPSCounter();
  
  /**
   * フレームタイマーをスタートする
   */
  void startTimer() {
    
    cpucnt.init();
    frameWatch.start( const Duration(milliseconds:20), () {
      // フレームの処理
      cpucnt.open();
      
      if( _screen!=null ) {
        _screen.onTimer();
      }
      
      cpucnt.shut();
    });
  }
  
  /**
   * フレームタイマーを停止する
   */
  void stopTimer() {
    frameWatch.dispose();
    cpucnt.dispose();
  }
  
  
  math.Random  rand = new math.Random(3000);
  
  num randRange( num n1, num n2 ) {
    var r = rand.nextDouble();
    return (n1*r) + (n2*(1.0-r));
  }
  
  /** 再描画をリクエストする */
  void repaint() {
    _repaintCount++;
  }
  
  bool popRepaintRequest() {
    var r = _repaintCount > 0;
    _repaintCount = 0;
    return r;
  }
  
  int _repaintCount = 0;
}

GEng geng = new GEng();


/**
 * ハイスコア管理
 * 
 */
class HiScoreManager {
  
  Map<String,List<int>> _scoresMap;
  
  /** 各スコアの最大登録数 */
  int maxLength = 5;

  /**
   * データの読み込み、もしくは初期化
   */
  void init() {
    
    if( window.localStorage.containsKey("hiscore") ) {
      // LocalStorageから読み込み
      var savedData = window.localStorage["hiscore"];
      _scoresMap = new JsonDecoder(null).convert( savedData );
    } else {
      // 初期設定
      _scoresMap = {};
    }
  }
  
  /**
   * 指定した種類のハイスコアを取得します。読み取り専用です
   */
  List<String> getScoreTexts( String kind ) {
    var list = (_scoresMap.containsKey(kind)) ? _scoresMap[kind] : defaultScores;
    return list.map((e)=>e.toString()).toList(growable:false);
  }
  
  var defaultScores=[ 500, 400, 300, 200, 100 ]; 
  /**
   * 新しいスコアを登録する
   * 戻りは登録された順位です（0始まり）
   * ランク外ならthrowされます
   */
  int addNewRecord( String kind, int newScore ) {
    
    // なかったらデフォルトハイスコアで初期化する
    if( _scoresMap.containsKey(kind)==false )
      _scoresMap[kind] = defaultScores;
    
    var _list = _scoresMap[kind];
    
    for( int i=0; i<_list.length; i++ ) {
      if( newScore > _list[i] ) {
        // 追加
        _list.insert( i, newScore );
        // はみ出した分を削除する
        if( _list.length > maxLength )
          _list.removeRange(maxLength, _list.length);
        // callback
        writeData();
        
        return i;
      }
    }
    
    throw "out of ranking";
  }
  
  /**
   * ハイスコアを永続化します。
   * 普通はaddNewRecordされる度に自動で呼ばれます
   */
  void writeData() {
    var stringfy = new JsonEncoder().convert( _scoresMap );
    window.localStorage["hiscore"] = stringfy;
  }
  
  /**
   * ハイスコアデータをクリアします
   */
  void allClear() {
    window.localStorage.remove("hiscore");
    init();
  }
}

