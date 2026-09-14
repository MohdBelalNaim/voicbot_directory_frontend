class VadProcessor extends AudioWorkletProcessor {
  constructor() {
    super();
    this._threshold = 0.25;
    this._framesRequired = 8;   // ~8 * 128/48000 ≈ 21ms of sustained speech
    this._framesAbove = 0;
    this._triggered = false;
    this._cooldownFrames = 0;
    this.port.onmessage = (e) => {
      if (e.data && e.data.threshold !== undefined) {
        this._threshold = e.data.threshold;
      }
    };
  }

  process(inputs) {
    const input = inputs[0];
    if (!input || !input[0]) return true;
    const samples = input[0];

    // RMS energy of the mic signal
    let sumSq = 0;
    for (let i = 0; i < samples.length; i++) {
      sumSq += samples[i] * samples[i];
    }
    const rms = Math.sqrt(sumSq / samples.length);

    if (this._cooldownFrames > 0) {
      this._cooldownFrames--;
      return true;
    }

    if (rms > this._threshold) {
      this._framesAbove++;
      if (!this._triggered && this._framesAbove >= this._framesRequired) {
        this._triggered = true;
        this.port.postMessage({ type: 'speech', rms });
        // 800ms cooldown before firing again
        this._cooldownFrames = Math.round(0.8 * sampleRate / 128);
      }
    } else {
      this._framesAbove = 0;
      this._triggered = false;
    }

    return true;
  }
}

registerProcessor('vad-processor', VadProcessor);
