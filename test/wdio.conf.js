var timeout = 15 * 60 * 1000;

exports.config = {
  port: 4723,
  logLevel: 'verbose',
  connectionRetryTimeout: timeout,
  connectionRetryCount: 1,

  capabilities: [{
    platformName: 'Android',
    deviceName: 'any',
    app: '../platforms/android/app/build/outputs/apk/debug/app-debug.apk',
    autoWebview: true,
    autoGrantPermissions: true,
    adbExecTimeout: timeout,
  }],

  specs: ['./spec/**/*.js'],
  services: ['appium'],
  reporters: ['spec'],
  framework: 'jasmine',

  jasmineNodeOpts: {
    defaultTimeoutInterval: timeout,
  },
};
