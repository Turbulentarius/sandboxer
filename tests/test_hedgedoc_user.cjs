const { test } = require('node:test')
const assert = require('node:assert/strict')
const { mkdtempSync, mkdirSync, copyFileSync, writeFileSync, rmSync, existsSync } = require('node:fs')
const { tmpdir } = require('node:os')
const { join, resolve } = require('node:path')
const { spawnSync } = require('node:child_process')

const localScript = resolve(__dirname, '../config/install-scripts/hedgedoc-user.js')
const script = existsSync(localScript) ? localScript : '/hedgedoc/create-sandboxer-user.js'

function run (mode, password) {
  const root = mkdtempSync(join(tmpdir(), 'hedgedoc-user-test-'))
  try {
    mkdirSync(join(root, 'lib'))
    copyFileSync(script, join(root, 'user.cjs'))
    writeFileSync(join(root, 'lib/models.js'), `
      // Model imports in HedgeDoc keep resources active after DB closure.
      setInterval(() => {}, 1000)
      module.exports = {
        User: {
          async findOne () {
            if (process.env.TEST_MODE === 'lookup-failure') throw new Error('lookup failed')
            return process.env.TEST_MODE === 'existing' ? {} : null
          },
          async create ({ email, password }) {
            if (process.env.TEST_MODE === 'create-failure') throw new Error('create failed')
            if (email !== 'sandboxer@sandboxer.localhost' || password !== 'test-password') {
              throw new Error('unexpected credentials')
            }
            console.log('CREATE_CALLED')
          }
        },
        sequelize: { async close () { console.log('DB_CLOSED') } }
      }
    `)
    const env = { ...process.env, TEST_MODE: mode }
    delete env.SANDBOXER_HEDGEDOC_PASSWORD
    if (password !== undefined) env.SANDBOXER_HEDGEDOC_PASSWORD = password
    const result = spawnSync(process.execPath, [join(root, 'user.cjs')], {
      env, encoding: 'utf8', timeout: 5000
    })
    assert.ifError(result.error)
    assert.match(result.stdout, /DB_CLOSED/)
    return result
  } finally {
    rmSync(root, { recursive: true, force: true })
  }
}

test('existing account exits successfully without creating or requiring a password', () => {
  const result = run('existing')
  assert.equal(result.status, 0)
  assert.match(result.stdout, /already exists/)
  assert.doesNotMatch(result.stdout, /CREATE_CALLED/)
})

test('missing account is created and the process exits', () => {
  const result = run('missing', 'test-password')
  assert.equal(result.status, 0)
  assert.match(result.stdout, /CREATE_CALLED/)
})

test('missing or empty password fails without creating an account', () => {
  for (const password of [undefined, '']) {
    const result = run('missing', password)
    assert.equal(result.status, 1)
    assert.match(result.stderr, /SANDBOXER_HEDGEDOC_PASSWORD must be set/)
    assert.doesNotMatch(result.stdout, /CREATE_CALLED/)
  }
})

for (const mode of ['lookup-failure', 'create-failure']) {
  test(mode + ' closes the database and exits with failure', () => {
    const result = run(mode, 'test-password')
    assert.equal(result.status, 1)
    assert.match(result.stderr, /failed/)
  })
}
