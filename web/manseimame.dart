import 'dart:html';
import 'dart:async';

import 'geng.dart';
import 'vector.dart';


void main() {
  
  Timer.run( () {
    
    // 画像読み込み
    geng.imageMap
      ..put("bg", "./img/bg.png")
      ..put("bu01", "./img/bu01.png")
      ..put("bu02", "./img/bu02.png")
      ..put("bu03", "./img/bu03.png")
      ..put("hit", "./img/hit.png")
      ..put("mame", "./img/mame.png")
      ..put("mameicon", "./img/mameicon.png")
      ..put("oni_b01", "./img/oni_b01.png")
      ..put("oni_b02", "./img/oni_b02.png")
      ..put("oni_b03", "./img/oni_b03.png")
      ..put("oni_b04", "./img/oni_b04.png")
      ..put("oni_b05", "./img/oni_b05.png")
      ..put("oni_r01", "./img/oni_r01.png")
      ..put("oni_r02", "./img/oni_r02.png")
      ..put("oni_r03", "./img/oni_r03.png")
      ..put("oni_r04", "./img/oni_r04.png")
      ..put("oni_r05", "./img/oni_r05.png")
      ..put("resultbg", "./img/resultbg.png")
      ..put("start", "./img/start.png")
      ..put("starttext", "./img/starttext.png")
      ..put("title", "./img/title.png")
      ..put("gamebg", "./img/oldbg.png")
      ;
    
    // サウンド読み込み
    geng.soundManager.put("gameover","./sound/gameover.ogg");
    geng.soundManager.put("miss","./sound/miss.ogg");
    geng.soundManager.put("throw","./sound/throw.ogg");
    
    // ハイスコアデータ読み込み
    geng.hiscoreManager.init();
    
    // SoundのOn/Off
    bool sound = window.localStorage.containsKey("sound") ? window.localStorage["sound"]=="true" : false;
    geng.soundManager.soundOn = sound;
    
    // Canvas
    num scale = isMobileDevice() ? 0.5 : 1;
    geng.initField( width:480, height:480, scale:scale );
    
    query("#place").append( geng.canvas );
    
    // 開始
    geng.screen = new Title();
    geng.startTimer();
  });
}

TextRender  tren = new TextRender()
..fontFamily = fontFamily
..fontSize = "28pt"
..textAlign = "center"
..textBaseline = "middle"
..fillColor = Color.Black
;

/***********
 * 
 * タイトル画面の表示
 * 
 */
class Title extends GScreen {
  
  void onStart() {
    geng.objlist.disposeAll();
    
    //---------------------
    // StartGameボタン配置
    var playbtn = new GButton(text:"ゲームスタート",width:300,height:60)
    ..renderer = new ImageButtonRender("starttext").render
    ..onPress = (){
      geng.soundManager.play("throw");
      new Timer( const Duration(milliseconds:500), () {
        geng.screen = new GameScreen();
      });
    }
    ..x = 400
    ..y = 380;
    geng.objlist.add( playbtn );
    btnList.add( playbtn );
    
    //---------------------
    // 最前面描画処理
    onBackRender= ( GCanvas2D canvas ) {
      canvas.c.drawImage(geng.imageMap["title"], 0, 0);
    };
    
  }
}

/**
 * ゲーム画面
 */
class GameScreen extends GScreen {
  
  int score = 100;
  int mameCnt = 3;
  
  var imgBg;
  var imgMameIcon;
  var scoreTren;
  
  Boochan boo;
  
  
  void onStart() {
    geng.objlist.disposeAll();
    
    imgBg = geng.imageMap["gamebg"];
    imgMameIcon = geng.imageMap["mameicon"];
    scoreTren = new TextRender.from(tren)
    ..fontSize = "16px"
    ..textAlign = "right"
    ..textBaseline = "top";
    
    // 鬼表示
    var redOni = new Oni.blue();
    geng.objlist.add( redOni );

    var blueOni = new Oni.blue();
    geng.objlist.add( blueOni );

    // Start表示
    var start = new StartCounter()
    ..callback = () {
      
      // ぶーちゃん
      boo = new Boochan();
      geng.objlist.add( boo );
      
    };
    geng.objlist.add(start);
    start.start();
    
    // マウスハンドラ用透明なボタン
    GButton mouse = new GButton(x:240, y:240, width:480, height:480 );
    mouse.renderer = (c,b) {};
    mouse.onPress = () {
      // クリックされた
      if( mameCnt > 0 ) {
        // まめ投げる
        geng.soundManager.play("throw");
        mouse.isPress = false;
        boo.throwAway();
        // まめ減らす
        mameCnt--;
      }
    };
    btnList.add(mouse);
    
    //---------------------
    // 最背面表示
    onBackRender= ( GCanvas2D canvas ) {
      canvas.c.drawImage(imgBg, 0, 0);
      
      // 豆表示
      var x = 340;
      for( int i=0; i<mameCnt; i++ ) {
        canvas.c.drawImage(imgMameIcon, x, 400);
        x += 40;
      }
      // 得点表示
      canvas.drawTexts(scoreTren, ["$score"], 100, 400);
    };
  }
}

/**
 * ぶーちゃん
 */
class Boochan extends GObj {
  
  Sprite sp01,sp02,spThrow;
  int width=83;
  
  Vector  pos = new Vector();
  var _anime;
  
  void onInit() {
    sp01 = new Sprite.withImage("bu01")
    ..offset = new Point(83~/2,105~/2);
    sp02 = new Sprite.withImage("bu02")
    ..offset = new Point(83~/2,105~/2);
    spThrow = new Sprite.withImage("bu03");
    
    pos.x = -width.toDouble();
    pos.y = 320.0;
    
    _anime = new Animation.mugen()
    ..milliseconds = 500
    ..renderList = [
        sp01.render,
        sp02.render,
    ]
    ..start();
  }
  
  void onProcess( RenderList renderList ) {
    // 座標をすすめる
    pos.x += 1;
    // 画面外判定
    if( pos.x >= (480+width) ) {
      dispose();
      print("oreaida");
      // ゲーム直後メッセージ表示に遷移
    }
    // スプライトに座標転写…これは無駄だ。Spriteにアニメ機能をもたせよう！
    sp01.x = pos.x;
    sp01.y = pos.y;
    sp02.x = pos.x;
    sp02.y = pos.y;
    
    renderList.add( 100, _anime.render );
  }
  
  void onDispose() {
    _anime.stop();
  }
  
  void throwAway() {
    Mame  mame = new Mame();
    mame.pos.set( pos );
    mame.speed.y = -5.0;
    geng.objlist.add( mame );
  }
}

/**
 * まめ
 */
class Mame extends GObj {

  Sprite  _sp;
  final Vector  pos = new Vector();
  final Vector  speed = new Vector();
  
  void onInit() {
    _sp = new Sprite.withImage("mame")
    ..offset = new Point(10,10);
  }
  
  void onProcess( RenderList renderList ) {
    // まめをすすめる
    pos.add(speed);
    // 画面外判定
    if( pos.y < -_sp.height )
      dispose();
    // 鬼に当たり判定
    
    _sp.x = pos.x;
    _sp.y = pos.y;
    
    renderList.add( 100, _sp.render );
  }
  
  void onDispose() {
  }
}


/*
 * 鬼
 */
class Oni extends GObj {
  
  static var  centerData = {
    "oni_r01" : [124,146],
    "oni_r02" : [125,144],
    "oni_r03" : [125,150],
    "oni_r04" : [120,155],
    "oni_r05" : [132,159],
    
    "oni_b01" : [109,145],
    "oni_b02" : [109,156],
    "oni_b03" : [109,159],
    "oni_b04" : [114,145],
    "oni_b05" : [126,149],
  };
  
  Sprite  sp1,sp2,sp3,sp4,sp5;
  num x,y;
  
  Oni.blue() {
    sp1 = new Sprite.withImage("oni_b01")
    ..offset = new Point( 124, 146 );
    sp2 = new Sprite.withImage("oni_b02")
    ..offset = new Point( 125, 144 );
    sp3 = new Sprite.withImage("oni_b03")
    ..offset = new Point( 125, 150 );
    sp4 = new Sprite.withImage("oni_b04")
    ..offset = new Point( 120, 155 );
    sp5 = new Sprite.withImage("oni_b04")
    ..offset = new Point( 132, 159 );
  }
  
  void onInit() {
    y = 156;
    x = 140;
  }
  void onProcess( RenderList renderList ) {
    var sp = sp1;
    sp.x = this.x;
    sp.y = this.y;
    renderList.add(1000, sp.render);
  }
  void onDispose() {
  }
}

/**
 * スタート時の表示
 */
class StartCounter extends GObj {
  
  var _loop;
  var callback;
  
  void onInit() {
    
    var img = geng.imageMap["start"];
    num x = (480 - img.width) ~/ 2;
    num y = 200 - (img.height ~/ 2);
    
    _loop = new Animation.loop( 3, (){
      callback();
      // 自身の廃棄処理
      dispose();
    })
    ..milliseconds = 500
    ..renderList = [
        (canvas) { canvas.c.drawImage(img, x, y); },
        (canvas) { },
    ];
  }
  void onProcess( RenderList renderList ) {
    renderList.add(1000, _loop.render );
  }
  void onDispose() {
    _loop.stop();
  }
  
  void start() {
    _loop.start();
  }
}

class Animation {
  
  List<Render>  renderList;
  int count = 0;
  int milliseconds = 0;
  var animeEndCallback;
  
  var _timer;
  
  /** 有限ループのアニメ。アニメ終了時にcallbackできる */
  Animation.loop( int times, var callback ) {
    animeEndCallback = () {
      times--;
      if( times==0 ) {
        stop();
        callback();
      } else {
        count=0;
      }
    };
  }
  /** 無限ループアニメ */
  Animation.mugen() {
    animeEndCallback = () => count=0;
  }
  /** 1ショットだけのアニメ */
  Animation.oneShot() {
    animeEndCallback = () => stop();
  }
  
  /** レンダリング */
  void render( GCanvas2D canvas ) {
    renderList[count](canvas);
  }
  
  void start() {
    _timer = new Timer.periodic( new Duration(milliseconds:milliseconds), (t) {
      count++;
      if( count >= renderList.length )
        animeEndCallback();
    });
  }
  
  void stop() {
    _timer.cancel();
  }
  
}
