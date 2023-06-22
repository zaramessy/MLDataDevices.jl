module LuxDeviceUtilsLuxAMDGPUExt

isdefined(Base, :get_extension) ? (using LuxAMDGPU) : (using ..LuxAMDGPU)
using ChainRulesCore, LuxDeviceUtils, Random
import Adapt: adapt_storage, adapt
import ChainRulesCore as CRC

function __init__()
    LuxDeviceUtils.ACCELERATOR_STATE_CHANGED[] = true
    return
end

# Device Transfer
## To GPU
adapt_storage(::LuxAMDGPUAdaptor, x) = roc(x)
adapt_storage(::LuxAMDGPUAdaptor, rng::AbstractRNG) = rng

## Chain Rules
CRC.rrule(::Type{Array}, x::ROCArray) = Array(x), Δ -> (NoTangent(), roc(Δ))

function CRC.rrule(::typeof(adapt_storage), to::LuxCPUAdaptor, x::AMDGPU.AnyROCArray)
    function ∇adapt_storage(Δ)
        return (NoTangent(), NoTangent(), adapt_storage(LuxAMDGPUAdaptor(), Δ))
    end
    return adapt_storage(to, x), ∇adapt_storage
end

function CRC.rrule(::typeof(adapt_storage), to::LuxAMDGPUAdaptor, x::Array)
    function ∇adapt_storage(Δ)
        return (NoTangent(), NoTangent(), adapt_storage(LuxCPUAdaptor(), Δ))
    end
    return adapt_storage(to, x), ∇adapt_storage
end

end