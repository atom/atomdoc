module.exports = {
  getLinkMatch (text) {
    const m = text.match(/\{([\w.]+)\}/)
    if (m) {
      return m[1]
    } else {
      return null
    }
  }
}
