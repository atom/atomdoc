let Doc;
module.exports = Doc = class Doc {
  constructor(originalText) {
    this.originalText = originalText;
    this.visibility = 'Private';
  }

  isPublic() {
    return /public|essential|extended/i.test(this.visibility);
  }

  isInternal() {
    return /internal/i.test(this.visibility);
  }

  isPrivate() {
    return !this.isPublic() && !this.isInternal();
  }

  setReturnValues(returnValues) {
    if (this.returnValues) {
      this.returnValues = this.returnValues.concat(returnValues);
    } else {
      this.returnValues = returnValues;
    }
  }
};
