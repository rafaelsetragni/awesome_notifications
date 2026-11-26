#include "toast_activator.h"

#include <NotificationActivationCallback.h>

#include <atomic>
#include <mutex>

#include "win_utils.h"

namespace awesome_notifications {

namespace {

std::mutex gMutex;
ToastActivator::Callback gCallback;
DWORD gCookie = 0;

class Activator final : public INotificationActivationCallback {
 public:
  HRESULT STDMETHODCALLTYPE QueryInterface(REFIID riid, void** object) override {
    if (!object) return E_POINTER;
    if (riid == IID_IUnknown || riid == __uuidof(INotificationActivationCallback)) {
      *object = static_cast<INotificationActivationCallback*>(this);
      AddRef();
      return S_OK;
    }
    *object = nullptr;
    return E_NOINTERFACE;
  }
  ULONG STDMETHODCALLTYPE AddRef() override { return ++refs_; }
  ULONG STDMETHODCALLTYPE Release() override {
    ULONG refs = --refs_;
    if (refs == 0) delete this;
    return refs;
  }

  HRESULT STDMETHODCALLTYPE Activate(LPCWSTR, LPCWSTR invokedArgs,
                                     const NOTIFICATION_USER_INPUT_DATA* data,
                                     ULONG count) override {
    awn::Activation activation;
    if (invokedArgs) activation.arguments = WideToUtf8(invokedArgs);
    for (ULONG i = 0; data && i < count; ++i) {
      if (data[i].Key && data[i].Value)
        activation.userInputs[WideToUtf8(data[i].Key)] = WideToUtf8(data[i].Value);
    }
    ToastActivator::Callback callback;
    {
      std::lock_guard<std::mutex> lock(gMutex);
      callback = gCallback;
    }
    if (callback) callback(activation);
    return S_OK;
  }

 private:
  std::atomic<ULONG> refs_{1};
};

class Factory final : public IClassFactory {
 public:
  HRESULT STDMETHODCALLTYPE QueryInterface(REFIID riid, void** object) override {
    if (!object) return E_POINTER;
    if (riid == IID_IUnknown || riid == IID_IClassFactory) {
      *object = static_cast<IClassFactory*>(this);
      AddRef();
      return S_OK;
    }
    *object = nullptr;
    return E_NOINTERFACE;
  }
  // Static lifetime: the factory lives as long as the process.
  ULONG STDMETHODCALLTYPE AddRef() override { return 2; }
  ULONG STDMETHODCALLTYPE Release() override { return 1; }

  HRESULT STDMETHODCALLTYPE CreateInstance(IUnknown* outer, REFIID riid, void** object) override {
    if (!object) return E_POINTER;
    *object = nullptr;
    if (outer) return CLASS_E_NOAGGREGATION;
    auto* activator = new Activator();
    HRESULT hr = activator->QueryInterface(riid, object);
    activator->Release();
    return hr;
  }
  HRESULT STDMETHODCALLTYPE LockServer(BOOL) override { return S_OK; }
};

Factory gFactory;

}  // namespace

bool ToastActivator::Register(const GUID& clsid, Callback callback) {
  std::lock_guard<std::mutex> lock(gMutex);
  gCallback = std::move(callback);
  if (gCookie != 0) return true;
  HRESULT hr = ::CoRegisterClassObject(clsid, &gFactory, CLSCTX_LOCAL_SERVER, REGCLS_MULTIPLEUSE,
                                       &gCookie);
  return SUCCEEDED(hr);
}

void ToastActivator::Unregister() {
  std::lock_guard<std::mutex> lock(gMutex);
  gCallback = nullptr;
  if (gCookie != 0) {
    ::CoRevokeClassObject(gCookie);
    gCookie = 0;
  }
}

}  // namespace awesome_notifications
