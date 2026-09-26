'use strict'

const models = require('./lib/models')

const email = 'sandboxer@sandboxer.localhost'
const password = process.env.SANDBOXER_HEDGEDOC_PASSWORD

async function createDefaultUser () {
  try {
    const existingUser = await models.User.findOne({ where: { email } })
    if (existingUser) {
      console.log(`HedgeDoc user ${email} already exists; leaving it unchanged.`)
      return
    }

    if (typeof password !== 'string' || password.length === 0) {
      throw new Error('SANDBOXER_HEDGEDOC_PASSWORD must be set to create the default user.')
    }

    await models.User.create({ email, password })
    console.log(`Created HedgeDoc user ${email}.`)
  } finally {
    await models.sequelize.close()
  }
}

// HedgeDoc model imports leave a child process active even after the DB closes.
// Like its bundled bin/manage_users, explicitly exit after completing the work.
createDefaultUser()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
