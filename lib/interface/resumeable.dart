abstract class Resumeable {
  bool isPaused;

  Resumeable([this.isPaused = false]);

  void pause();
  void resume();
}
