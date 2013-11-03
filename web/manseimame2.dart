part of manseimame;

/** ステージクリア後の寸劇 */
class MessageScreen extends GScreen {
  
  List serifData;
  
  MessageScreen( List serif ) : serifData = serif;
  
  void onStart() {
    input = new InputHandler();
    
    int serifIndex = 0;
    
    //-----
    // マウスハンドラ用透明なボタン→セリフを進める
    input.onRelease = (e) {
      serifIndex++;
      if( serifIndex >= serifData.length ) {
        serifIndex--;
        // クリックされたらスコア表示画面に戻る
        geng.screen = new ScoreScreen();
      }
    };
    
    //------
    // 結果発表の描画
    onFrontRender = ( GCanvas2D canvas ) {
      canvas.drawTexts(messageTren, serifData[serifIndex], 25, 260);
    };
    
    //---------------------
    // 最背面表示
    onBackRender= drawGameBackground;
  }
}

/** ステージクリア後の寸劇 */
class MessageScreen2 extends GScreen {
  
  List serifData;
  
  MessageScreen2( List serif ) : serifData = serif;
  
  void onStart() {
    input = new InputHandler();
    
    int serifIndex = 0;
    
    //-----
    // ぶーちゃん
    Boochan boo = new Boochan();
    geng.objlist.add( boo );
    boo.pos.x = 240.0;
    
    //-----
    // マウスハンドラ用透明なボタン→セリフを進める
    input.onRelease = (e) {
      serifIndex++;
      if( serifIndex==3 ) {
        serifIndex=-1;
        input.onRelease = null;
        boo.start();
      }
    };
    
    boo.onOutOfScreen = () {
      // 一旦入力停止
      input.onRelease = null;
      // ぶーちゃん削除
      boo.dispose();
      // 鬼復活
      var redOni = geng.objlist.query("redOni") as Oni;
      redOni.fukkatsu();
      var blueOni = geng.objlist.query("blueOni") as Oni;
      blueOni.fukkatsu();
      // 鬼のセリフ
      serifIndex = 3;
      input.onRelease = (e) {
        serifIndex++;
        if( serifIndex >= serifData.length ) {
          serifIndex--;
          // クリックされたらスコア表示画面に戻る
          gameClearCount = 1;
          geng.screen = new GameScreen();
        }
      };
    };
    
    //------
    // 結果発表の描画
    onFrontRender = ( GCanvas2D canvas ) {
      if( serifIndex >= 0 )
        canvas.drawTexts(messageTren, serifData[serifIndex], 25, 260);
    };
    
    //---------------------
    // 最背面表示
    onBackRender= drawGameBackground;
  }
}

/** ２周めクリア後のステージクリア後の寸劇 */
class MessageScreen3 extends GScreen {
  
  List serifData;
  
  MessageScreen3( List serif ) : serifData = serif;
  
  void onStart() {
    input = new InputHandler();
    
    int serifIndex = 0;
    
    //-----
    // ぶーちゃん
    Boochan boo = new Boochan();
    geng.objlist.add( boo );
    boo.pos.x = 240.0;
    
    //-----
    // マウスハンドラ用透明なボタン→セリフを進める
    input.onRelease = (e) {
      serifIndex++;
      if( serifIndex==2 ) {
        input.onRelease = null;
        boo.start();
      }
    };
    
    boo.onOutOfScreen = () {
      // 一旦入力停止
      input.onRelease = null;
      // ぶーちゃん削除
      boo.dispose();
      // スコア表示画面に戻る
      gameClearCount = 2;
      geng.screen = new ScoreScreen();
    };
    
    //------
    // 結果発表の描画
    onFrontRender = ( GCanvas2D canvas ) {
      if( serifIndex >= 0 )
        canvas.drawTexts(messageTren, serifData[serifIndex], 25, 260);
    };
    
    //---------------------
    // 最背面表示
    onBackRender= drawGameBackground;
  }
}

class ScoreScreen extends GScreen {
  
  void onStart() {
    geng.objlist.disposeAll();
    
    //-----
    // マウスハンドラ用透明なボタン→セリフを進める
    input.onRelease = (e) {
      // 結果に応じて画面遷移
      switch(gameClearCount) {
        case 2:
          window.open(url02,"cleargame");
          break;
        case 1:
          window.open(url01,"cleargame");
          break;
        default:
      }
      geng.screen = new Title();
    };
    
    //---------------------
    // 最背面表示
    onBackRender= (canvas){
      canvas.c.drawImage(geng.imageMap["gamebg"], 0, 0);
      canvas.c.drawImage(geng.imageMap["resultbg"], (480-356)/2, (480-99)/2);
      // 得点表示
      canvas.drawTexts(scoreTren, ["$score"], 265, 242);
    };
    
    geng.soundManager.play("gameover");
  }
}

