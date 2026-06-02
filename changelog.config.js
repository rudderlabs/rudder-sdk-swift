'use strict'

// Extends the Angular conventional-changelog preset to also include
// 'refactor' and 'chore' commit types in the generated CHANGELOG.
module.exports = require('conventional-changelog-angular').then(angularPreset => {
  const originalTransform = angularPreset.conventionalChangelog.writerOpts.transform

  angularPreset.conventionalChangelog.writerOpts.transform = (commit, context) => {
    // Let the Angular preset handle feat, fix, perf, revert, etc.
    const result = originalTransform(commit, context)
    if (result) return result

    const clone = Object.assign({}, commit)
    if (commit.type === 'refactor') {
      clone.type = 'Refactors'
      return clone
    }
    if (commit.type === 'chore') {
      clone.type = 'Chores'
      return clone
    }
    return null
  }

  return angularPreset
})
