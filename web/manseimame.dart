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
  
  /** ゲームのスコア */
  int score = 0;
  /** まめの残り */
  int remainsOfMame = 3;
  
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
    var redOni = new Oni.red();
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
    
    //-------
    // まめと鬼の当たり判定
    var onis = [ redOni, blueOni ];
    var mameConf = (Mame mame) {
      for( Oni oni in onis ) {
        var onx = mame.getXOnY( oni.y );
        if( onx!=null ) {
          var s = oni.getScoreWithX( onx );
          if( s!=null ) {
            print( "hit s=$s onx=$onx" );
            oni.putHitMark( onx );
            mame.dispose();
            if( s==100 )
              oni.ouch();
            else
              oni.kayui();
            score += s;
          }
        }
      }
    };
    
    //-----
    // マウスハンドラ用透明なボタン→まめを投げる
    GButton mouse = new GButton(x:240, y:240, width:480, height:480 );
    mouse.renderer = (c,b) {};
    mouse.onPress = () {
      // クリックされた
      if( remainsOfMame > 0 ) {
        // まめ投げる
        geng.soundManager.play("throw");
        mouse.isPress = false;
        
        Mame  mame = new Mame()
        ..onForwarded = mameConf
        ..pos.set( boo.pos )
        ..speed.y = -5.0;
        
        geng.objlist.add( mame );
        
        // まめ減らす
        remainsOfMame--;
      }
    };
    btnList.add(mouse);
    
    //---------------------
    // 最背面表示
    onBackRender= ( GCanvas2D canvas ) {
      canvas.c.drawImage(imgBg, 0, 0);
      
      // 豆表示
      var x = 340;
      for( int i=0; i<remainsOfMame; i++ ) {
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
  
  Sprite sp;
  Sprite spThrow;
  int width=83;
  
  Vector  pos = new Vector();
  var _anime;
  
  void onInit() {
    var sp01 = new Sprite.withImage("bu01")
    ..offset = new Point(83~/2,105~/2);
    var sp02 = new Sprite.withImage("bu02")
    ..offset = new Point(83~/2,105~/2);
    spThrow = new Sprite.withImage("bu03");
    
    pos.x = -width.toDouble();
    pos.y = 320.0;
    
    _anime = new AnimationRender.mugen()
    ..milliseconds = 500
    ..spriteList = [sp01,sp02]
    ..start();
    
    sp = new Sprite.withRender( _anime.render, width:83, height:105 );
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
    sp.x = pos.x;
    sp.y = pos.y;
    
    renderList.add( 100, sp.render );
  }
  
  void onDispose() {
    _anime.stop();
  }
}

/**
 * まめ
 */
class Mame extends GObj {

  Sprite  _sp;
  final Vector  oldpos = new Vector();
  final Vector  pos = new Vector();
  final Vector  speed = new Vector();
  
  var onForwarded;
  
  void onInit() {
    _sp = new Sprite.withImage("mame")
    ..offset = new Point(14,5);
  }
  
  void onProcess( RenderList renderList ) {
    // まめをすすめる
    oldpos.set(pos);
    pos.add(speed);
    // 画面外判定
    if( pos.y < -_sp.height )
      dispose();
    // 鬼に当たり判定
    if( onForwarded!=null )
      onForwarded(this);
    
    _sp.x = pos.x;
    _sp.y = pos.y;
    
    renderList.add( 100, _sp.render );
  }
  
  num getXOnY( targety ) {
    var to = this.pos;
    if( oldpos.y < targety )
      return null;
    if( to.y > targety )
      return null;
    
    var dy1 = oldpos.y - targety;
    var dy2 = oldpos.y - to.y;
    
    var dx2 = to.x - oldpos.x;
    
    var dx1 = (dy1 / dy2) * dx2;
    
    return (oldpos.x + dx1);
  }
  
  void onDispose() {
  }
}


/*
 * 鬼
 */
class Oni extends GObj {
  
  Sprite  sp;
  Sprite  sp1,sp2,sp3,sp4,sp5;
  Sprite  hitSp;
  num x,y;
  var anime;
  final List<num>  hitPoints = new List();
  
  Oni.red() {
    sp1 = new Sprite.withImage("oni_r01")
    ..offset = new Point( 124, 146 );
    sp2 = new Sprite.withImage("oni_r02")
    ..offset = new Point( 125, 144 );
    sp3 = new Sprite.withImage("oni_r03")
    ..offset = new Point( 125, 150 );
    sp4 = new Sprite.withImage("oni_r04")
    ..offset = new Point( 120, 155 );
    sp5 = new Sprite.withImage("oni_r05")
    ..offset = new Point( 132, 159 );
    // 初期の位置
    y = 156;
    x = 140;
  }
  
  Oni.blue() {
    sp1 = new Sprite.withImage("oni_b01")
    ..offset = new Point( 109, 145 );
    sp2 = new Sprite.withImage("oni_b02")
    ..offset = new Point( 109, 156 );
    sp3 = new Sprite.withImage("oni_b03")
    ..offset = new Point( 109, 159 );
    sp4 = new Sprite.withImage("oni_b04")
    ..offset = new Point( 114, 145 );
    sp5 = new Sprite.withImage("oni_b05")
    ..offset = new Point( 126, 149 );
    // 初期の位置
    y = 156;
    x = 340;
  }
  
  void onInit() {
    sp = new Sprite.withRender((c,sp) => sp1.render(c), width:150, height:150 );
    hitSp = new Sprite.withImage("hit")
    ..offsetx = 13
    ..offsety = 10;
  }
  
  void onProcess( RenderList renderList ) {
    sp.x = this.x;
    sp.y = this.y;
    renderList.add(10, (c){
      sp.render(c);
      // ヒットマークを描画
      for( var p in hitPoints ) {
        hitSp.x = p+x;
        hitSp.y = y;
        hitSp.render(c);
      }
    });
  }
  
  int getScoreWithX( num px ) {
    var rd = px - x;
    var d = rd.abs();
    if( d < 5 ) {
      return 100;
    } else if( d < 12 ) {
      return 60;
    } else if( d < 20 ) {
      return 30;
    } else if( d < 46 ) {
      return 10;
    }
    return null;
  }
  
  void putHitMark( num px ) {
    var dx = px - x;
    hitPoints.add( dx );
  }
  
  /** あたり */
  void ouch() {
    if( anime==null ) {
      anime = new AnimationRender.mugen()
      ..milliseconds = 400
      ..spriteList = [ sp2, sp3 ]
      ..start();
      sp.sprenderer = anime.render;
    }
  }
  /** かゆい */
  void kayui() {
    if( anime==null ) {
      anime = new AnimationRender.mugen()
      ..milliseconds = 400
      ..spriteList = [ sp4, sp5 ]
      ..start();
      sp.sprenderer = anime.render;
    }
  }
  
  void onDispose() {
    if( anime!=null )
      anime.stop();
  }
}

/**
 * スタート時の表示
 */
class StartCounter extends GObj {
  
  Sprite sp;
  var _loop;
  var callback;
  
  void onInit() {
    
    Sprite  img = new Sprite.withImage("start");
    img.offsetx = img.width ~/ 2;
    img.offsety = img.height ~/ 2;
    
    _loop = new AnimationRender.loop( 3, (){
      callback();
      // 自身の廃棄処理
      dispose();
    })
    ..milliseconds = 500;
    _loop.add( img );
    _loop.add( null );
    
    sp = new Sprite.withRender(_loop.render, width:img.width , height:img.height )
    ..x = 480 ~/ 2
    ..y = 400 ~/ 2;
  }
  void onProcess( RenderList renderList ) {
    renderList.add(1000, sp.render );
  }
  void onDispose() {
    _loop.stop();
  }
  
  void start() {
    _loop.start();
  }
}

